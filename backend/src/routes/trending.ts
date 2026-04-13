import type { FastifyInstance } from 'fastify';
import type { TrendingRecipe } from '../data/trending.js';
import { getTodaysTrending, TRENDING_RECIPES } from '../data/trending.js';
import { fetchParallel } from '../services/fetcher.js';
import { extractRecipeFromHtml } from '../services/jsonld.js';

// Admin-added recipes (in memory — survives until Railway redeploy)
const adminRecipes: TrendingRecipe[] = [];

/**
 * GET /api/trending
 *
 * Returns curated + admin-added trending recipes.
 * Admin recipes go on top, curated fill the rest.
 */
export async function registerTrendingRoute(app: FastifyInstance): Promise<void> {
  app.get('/api/trending', async (request) => {
    const countParam = (request.query as { count?: string }).count;
    const count = Math.min(Math.max(parseInt(countParam || '8', 10) || 8, 1), 20);
    const today = new Date().toISOString().slice(0, 10);

    // Admin recipes first, then curated (deduplicated)
    const adminTitles = new Set(adminRecipes.map((r) => r.title.toLowerCase()));
    const curated = getTodaysTrending(count + 5).filter(
      (r) => !adminTitles.has(r.title.toLowerCase()),
    );
    const merged = [...adminRecipes, ...curated];

    return {
      recipes: merged.slice(0, count),
      date: today,
      adminCount: adminRecipes.length,
    };
  });

  /**
   * POST /api/trending/add
   *
   * Paste a recipe URL → backend auto-extracts everything → adds to trending.
   *
   * curl -X POST https://backend/api/trending/add \
   *   -H "Content-Type: application/json" \
   *   -d '{"url":"https://recipetineats.com/butter-chicken/","category":"VIRAL"}'
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

      const emoji = _pickEmoji(recipe.title);

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
   * List all admin-added recipes.
   */
  app.get('/api/trending/admin', async () => ({
    count: adminRecipes.length,
    recipes: adminRecipes,
  }));
}

function _pickEmoji(title: string): string {
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
