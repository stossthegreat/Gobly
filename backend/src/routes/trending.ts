import type { FastifyInstance } from 'fastify';
import type { TrendingRecipe } from '../data/trending.js';
import { getTodaysTrending, TRENDING_RECIPES } from '../data/trending.js';
import { fetchSpoonacularTrending } from '../services/spoonacular.js';
import { fetchParallel } from '../services/fetcher.js';
import { extractRecipeFromHtml } from '../services/jsonld.js';

// In-memory cache — refreshes once per day
let cachedRecipes: TrendingRecipe[] | null = null;
let cachedDate = '';

// Admin-added recipes (persisted in memory — survives until Railway redeploy)
const adminRecipes: TrendingRecipe[] = [];

/**
 * GET /api/trending
 *
 * Priority order:
 * 1. Spoonacular API (real, fresh, images always load) — called once/day
 * 2. Curated fallback (hand-picked elite recipes) — if Spoonacular fails
 *
 * Cached for 24 hours in memory. Zero cost per user request.
 * Add SPOONACULAR_API_KEY to Railway to activate live trending.
 */
export async function registerTrendingRoute(app: FastifyInstance): Promise<void> {
  app.get('/api/trending', async (request) => {
    const countParam = (request.query as { count?: string }).count;
    const count = Math.min(Math.max(parseInt(countParam || '8', 10) || 8, 1), 20);
    const today = new Date().toISOString().slice(0, 10);

    // Merge admin-added recipes on top of cached/curated
    const mergeAdmin = (base: TrendingRecipe[]) => {
      // Admin recipes go first, then fill from base (deduplicated)
      const adminTitles = new Set(adminRecipes.map((r) => r.title.toLowerCase()));
      const deduped = base.filter(
        (r) => !adminTitles.has(r.title.toLowerCase()),
      );
      return [...adminRecipes, ...deduped];
    };

    // Return cache if still fresh (same day)
    if (cachedRecipes && cachedDate === today) {
      const merged = mergeAdmin(cachedRecipes);
      return {
        recipes: merged.slice(0, count),
        date: today,
        source: 'cache',
      };
    }

    // Try Spoonacular first
    const spoonKey = process.env.SPOONACULAR_API_KEY;
    if (spoonKey) {
      try {
        const recipes = await fetchSpoonacularTrending(spoonKey, count + 4);
        if (recipes.length > 0) {
          cachedRecipes = recipes;
          cachedDate = today;
          app.log.info(
            `Trending refreshed from Spoonacular: ${recipes.length} recipes`,
          );
          return {
            recipes: recipes.slice(0, count),
            date: today,
            source: 'spoonacular',
          };
        }
      } catch (err) {
        app.log.warn({ err }, 'Spoonacular trending fetch failed, using fallback');
      }
    }

    // Fallback to curated list
    const fallback = getTodaysTrending(count);
    cachedRecipes = fallback;
    cachedDate = today;
    const merged = mergeAdmin(fallback);
    return {
      recipes: merged.slice(0, count),
      date: today,
      source: 'curated',
    };
  });

  /**
   * POST /api/trending/add
   *
   * Admin endpoint — paste a recipe URL and it auto-extracts everything.
   * The recipe gets added to the top of trending immediately.
   *
   * Body: { "url": "https://...", "category": "VIRAL" (optional) }
   *
   * Usage:
   * curl -X POST https://your-backend.up.railway.app/api/trending/add \
   *   -H "Content-Type: application/json" \
   *   -d '{"url":"https://www.recipetineats.com/butter-chicken/"}'
   */
  app.post<{
    Body: { url: string; category?: string };
  }>('/api/trending/add', async (request, reply) => {
    const { url, category } = request.body;

    if (!url || typeof url !== 'string' || !url.startsWith('http')) {
      return reply.status(400).send({ error: 'A valid URL is required' });
    }

    try {
      const [result] = await fetchParallel([url]);
      if (!result.html) {
        return reply.status(422).send({ error: 'Could not fetch the page' });
      }

      const recipe = extractRecipeFromHtml(result.html, url);
      if (!recipe) {
        return reply.status(422).send({ error: 'No recipe found on this page' });
      }

      // Pick an emoji based on title
      const emoji = pickEmoji(recipe.title);

      const trending: TrendingRecipe = {
        id: `admin_${Date.now()}`,
        title: recipe.title,
        source: recipe.source.name,
        sourceUrl: recipe.source.url,
        image: recipe.image,
        emoji,
        rating: recipe.rating.value || 4.8,
        time: recipe.time.display,
        category: category || 'VIRAL',
        description: recipe.description.slice(0, 120),
      };

      adminRecipes.unshift(trending);
      // Invalidate cache so next GET picks up the new recipe
      cachedDate = '';

      app.log.info(`Admin added trending: "${recipe.title}" from ${url}`);

      return {
        added: trending,
        totalAdmin: adminRecipes.length,
        totalAll: adminRecipes.length + TRENDING_RECIPES.length,
      };
    } catch (err) {
      app.log.error({ err }, 'trending/add failed');
      return reply.status(500).send({
        error: err instanceof Error ? err.message : String(err),
      });
    }
  });

  /**
   * GET /api/trending/admin
   * List all admin-added recipes (for debugging).
   */
  app.get('/api/trending/admin', async () => ({
    count: adminRecipes.length,
    recipes: adminRecipes,
  }));
}

function pickEmoji(title: string): string {
  const t = title.toLowerCase();
  if (t.includes('chicken')) return '🍗';
  if (t.includes('pasta') || t.includes('spaghetti')) return '🍝';
  if (t.includes('burger')) return '🍔';
  if (t.includes('pizza')) return '🍕';
  if (t.includes('taco')) return '🌮';
  if (t.includes('salad')) return '🥗';
  if (t.includes('soup') || t.includes('stew')) return '🍲';
  if (t.includes('cake') || t.includes('brownie')) return '🍰';
  if (t.includes('fish') || t.includes('salmon')) return '🐟';
  if (t.includes('steak') || t.includes('beef')) return '🥩';
  if (t.includes('egg')) return '🍳';
  if (t.includes('rice') || t.includes('curry')) return '🍛';
  if (t.includes('bread')) return '🍞';
  if (t.includes('pancake')) return '🥞';
  return '🍽️';
}
