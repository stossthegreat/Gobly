import type { FastifyInstance } from 'fastify';
import { getTodaysTrending } from '../data/trending.js';

/**
 * GET /api/trending
 *
 * Returns today's curated trending recipes. Rotates daily from
 * a hand-picked list of elite recipes. No external API dependency.
 *
 * To update the trending list: edit backend/src/data/trending.ts,
 * commit, push to the backend repo. Railway auto-deploys.
 */
export async function registerTrendingRoute(app: FastifyInstance): Promise<void> {
  app.get('/api/trending', async (request) => {
    const countParam = (request.query as { count?: string }).count;
    const count = Math.min(
      Math.max(parseInt(countParam || '6', 10) || 6, 1),
      TRENDING_RECIPES_COUNT,
    );
    return {
      recipes: getTodaysTrending(count),
      date: new Date().toISOString().slice(0, 10),
    };
  });
}

// Expose count for clamping
import { TRENDING_RECIPES } from '../data/trending.js';
const TRENDING_RECIPES_COUNT = TRENDING_RECIPES.length;
