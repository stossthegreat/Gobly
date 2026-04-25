import cron from 'node-cron';
import type { FastifyBaseLogger } from 'fastify';
import { braveSearch } from './brave.js';
import { fetchParallel } from './fetcher.js';
import { extractRecipeFromHtml } from './jsonld.js';
import type { TrendingRecipe } from '../data/trending.js';

/**
 * Weekly trending-recipe pipeline.
 *
 * Every Sunday at 03:00 UTC we ask Brave for a handful of "what's going viral
 * in food right now" queries, filter down to a hand-picked list of authority
 * recipe domains, fetch each page, pull a real Recipe out of its JSON-LD, and
 * keep the top 7 that have real images.
 *
 * The cached list is served by GET /api/trending. If the cache is empty
 * (first boot or a fetch failure), the route falls back to the curated
 * hard-coded list in data/trending.ts.
 */

const ALLOWED_DOMAINS = new Set([
  'delish.com',
  'bonappetit.com',
  'cooking.nytimes.com',
  'food52.com',
  'tasty.co',
  'bbcgoodfood.com',
  'allrecipes.com',
  'epicurious.com',
  'seriouseats.com',
  'halfbakedharvest.com',
  'smittenkitchen.com',
  'foodnetwork.com',
  'thekitchn.com',
  'recipetineats.com',
  'pinchofyum.com',
  'budgetbytes.com',
  'thepioneerwoman.com',
  'loveandlemons.com',
]);

const DISCOVERY_QUERIES = [
  'viral tiktok recipe this week',
  'most popular recipe right now',
  'trending dinner recipe',
  'viral pasta recipe',
  'trending chicken recipe',
  'best new recipe bon appetit',
  'delish most popular recipe',
  'half baked harvest viral',
];

const TARGET_COUNT = 7;

let cache: TrendingRecipe[] = [];
let lastRefresh: Date | null = null;
let refreshing = false;

export function getCachedTrending(): TrendingRecipe[] {
  return cache;
}

export function lastTrendingRefresh(): Date | null {
  return lastRefresh;
}

function hostOf(url: string): string {
  try {
    return new URL(url).host.replace(/^www\./, '').toLowerCase();
  } catch {
    return '';
  }
}

function pickEmoji(title: string): string {
  const t = title.toLowerCase();
  if (t.includes('chicken')) return '🍗';
  if (t.includes('pasta') || t.includes('spaghetti') || t.includes('noodle')) return '🍝';
  if (t.includes('burger')) return '🍔';
  if (t.includes('pizza')) return '🍕';
  if (t.includes('taco')) return '🌮';
  if (t.includes('salad')) return '🥗';
  if (t.includes('soup') || t.includes('stew')) return '🍲';
  if (t.includes('cake') || t.includes('brownie') || t.includes('cookie')) return '🍰';
  if (t.includes('fish') || t.includes('salmon') || t.includes('tuna')) return '🐟';
  if (t.includes('steak') || t.includes('beef')) return '🥩';
  if (t.includes('egg')) return '🍳';
  if (t.includes('rice') || t.includes('curry')) return '🍛';
  if (t.includes('bread') || t.includes('focaccia')) return '🍞';
  if (t.includes('pancake') || t.includes('waffle')) return '🥞';
  if (t.includes('shrimp') || t.includes('prawn')) return '🍤';
  if (t.includes('pork')) return '🥓';
  return '🍽️';
}

function normalizeTitle(s: string): string {
  return s.toLowerCase().replace(/\s+/g, ' ').trim();
}

export async function refreshTrending(log: FastifyBaseLogger): Promise<TrendingRecipe[]> {
  if (refreshing) {
    log.info('trending refresh already in flight — skipping');
    return cache;
  }
  refreshing = true;
  log.info('trending refresh: starting');

  try {
    // 1. Gather candidate URLs across all discovery queries.
    const seenHosts: Record<string, number> = {};
    const candidates: string[] = [];

    for (const q of DISCOVERY_QUERIES) {
      try {
        const results = await braveSearch(q, 10);
        for (const r of results) {
          const host = hostOf(r.url);
          if (!ALLOWED_DOMAINS.has(host)) continue;
          // Cap 2 hits per domain so we don't end up with 7 recipes from one site.
          seenHosts[host] = (seenHosts[host] || 0) + 1;
          if (seenHosts[host] > 2) continue;
          if (candidates.includes(r.url)) continue;
          candidates.push(r.url);
        }
      } catch (err) {
        log.warn({ err, query: q }, 'brave query failed');
      }
      // Respect Brave free-tier rate limit (1 req/sec).
      await new Promise((r) => setTimeout(r, 1100));
    }

    log.info({ candidateCount: candidates.length }, 'trending refresh: candidates gathered');
    if (candidates.length === 0) {
      throw new Error('no candidate URLs');
    }

    // 2. Fetch all in parallel and extract recipes.
    const fetched = await fetchParallel(candidates.slice(0, 30));
    const results: TrendingRecipe[] = [];
    const seenTitles = new Set<string>();

    for (const f of fetched) {
      if (!f.html) continue;
      const recipe = extractRecipeFromHtml(f.html, f.url);
      if (!recipe) continue;
      if (!recipe.title || recipe.title.length < 5) continue;
      if (!recipe.image || !/^https?:\/\//.test(recipe.image)) continue;

      const tkey = normalizeTitle(recipe.title);
      if (seenTitles.has(tkey)) continue;
      seenTitles.add(tkey);

      results.push({
        id: `auto_${Date.now()}_${results.length}`,
        title: recipe.title,
        source: recipe.source.name,
        sourceUrl: recipe.source.url,
        image: recipe.image,
        emoji: pickEmoji(recipe.title),
        rating: recipe.rating.value || 4.8,
        time: recipe.time.display || '—',
        category: 'VIRAL',
        description:
          (recipe.description || '').slice(0, 140) ||
          'Trending this week on the internet.',
      });

      if (results.length >= TARGET_COUNT) break;
    }

    if (results.length === 0) {
      throw new Error('no parseable recipes in candidates');
    }

    cache = results;
    lastRefresh = new Date();
    log.info(
      { count: results.length, sources: results.map((r) => r.source) },
      'trending refresh: complete',
    );
    return cache;
  } catch (err) {
    log.error({ err }, 'trending refresh failed — keeping previous cache');
    return cache;
  } finally {
    refreshing = false;
  }
}

/**
 * Kick off the scheduler: a first refresh in the background on boot, then a
 * weekly cron at 03:00 UTC every Sunday.
 */
export function startTrendingScheduler(log: FastifyBaseLogger): void {
  // Fire-and-forget initial fetch. Don't block server startup — the route
  // falls back to the hard-coded list until this resolves.
  void refreshTrending(log);

  // Sunday 03:00 UTC.
  cron.schedule(
    '0 3 * * 0',
    () => {
      log.info('trending scheduler: weekly tick');
      void refreshTrending(log);
    },
    { timezone: 'UTC' },
  );

  log.info('trending scheduler: registered (Sundays 03:00 UTC)');
}
