import type { FastifyInstance } from 'fastify';
import type { TrendingRecipe } from '../data/trending.js';
import { getTodaysTrending } from '../data/trending.js';
import { fetchSpoonacularTrending } from '../services/spoonacular.js';

// In-memory cache — refreshes once per day
let cachedRecipes: TrendingRecipe[] | null = null;
let cachedDate = '';

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

    // Return cache if still fresh (same day)
    if (cachedRecipes && cachedDate === today) {
      return {
        recipes: cachedRecipes.slice(0, count),
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
    return {
      recipes: fallback.slice(0, count),
      date: today,
      source: 'curated',
    };
  });
}
