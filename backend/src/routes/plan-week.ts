import type { FastifyInstance } from 'fastify';
import type { Recipe } from '../types/recipe.js';
import { generateWeekPlan } from '../services/openai.js';
import { webSearch } from '../services/web_search.js';
import { fetchParallel } from '../services/fetcher.js';
import { extractRecipeFromHtml } from '../services/jsonld.js';
import { eliteRank } from '../services/ranker.js';
import { isBlocked } from '../data/domains.js';

interface PlanWeekRequest {
  prompt: string; // e.g., "Mediterranean this week, quick meals"
  userContext?: string;
  days?: number; // 1–7, default 7
}

interface PlanWeekResponse {
  prompt: string;
  plan: Record<string, Record<string, { name: string; recipe: Recipe | null }>>;
  durationMs: number;
}

/**
 * POST /api/plan-week
 *
 * Generates a 21-meal week plan and fetches a real recipe for each:
 * 1. GPT-4o mini generates 21 specific dish names respecting user context
 * 2. For each dish, run a mini search pipeline in parallel
 * 3. Return the full plan with real recipes attached
 *
 * Target time: under 15 seconds for the full week.
 */
export async function registerPlanWeekRoute(app: FastifyInstance): Promise<void> {
  app.post<{ Body: PlanWeekRequest }>('/api/plan-week', async (request, reply) => {
    const { prompt, userContext, days } = request.body;

    if (!prompt || typeof prompt !== 'string') {
      return reply.status(400).send({ error: 'Prompt is required' });
    }

    // Clamp days to 1–7, default 7
    const dayCount = Math.max(1, Math.min(7, days ?? 7));

    const started = Date.now();

    try {
      // Step 1: Generate meal plan
      const plan = await generateWeekPlan(prompt, userContext, dayCount);

      // Step 2: Collect all 21 dish names
      const dishes: { day: string; meal: string; name: string }[] = [];
      for (const [day, meals] of Object.entries(plan)) {
        if (typeof meals !== 'object' || !meals) continue;
        for (const [meal, name] of Object.entries(meals as Record<string, string>)) {
          if (typeof name === 'string' && name.trim()) {
            dishes.push({ day, meal, name: name.trim() });
          }
        }
      }

      // Step 3: Search for each dish in parallel using the elite filter cascade.
      // Pulls 5 candidates per dish so the elite filter has options.
      const enriched = await Promise.all(
        dishes.map(async (dish) => {
          try {
            const results = await webSearch(dish.name, 6);
            const candidates = results
              .filter((r) => r.link && !isBlocked(r.link))
              .slice(0, 5);
            if (candidates.length === 0) return { ...dish, recipe: null };

            const fetched = await fetchParallel(candidates.map((c) => c.link));
            const recipes: Recipe[] = [];
            for (const result of fetched) {
              if (!result.html) continue;
              const recipe = extractRecipeFromHtml(result.html, result.url);
              if (recipe) recipes.push(recipe);
            }

            // Cascade-rank: best elite version, fallback to good, fallback to anything
            const ranked = eliteRank(recipes, 1);
            return { ...dish, recipe: ranked[0] || null };
          } catch (err) {
            app.log.warn({ err, dish: dish.name }, 'Failed to fetch recipe for dish');
            return { ...dish, recipe: null };
          }
        }),
      );

      // Step 4: Reshape into the response structure
      const responsePlan: PlanWeekResponse['plan'] = {};
      for (const item of enriched) {
        if (!responsePlan[item.day]) responsePlan[item.day] = {};
        responsePlan[item.day][item.meal] = {
          name: item.name,
          recipe: item.recipe,
        };
      }

      return {
        prompt,
        plan: responsePlan,
        durationMs: Date.now() - started,
      } satisfies PlanWeekResponse;
    } catch (err) {
      app.log.error({ err }, 'Plan-week pipeline failed');
      return reply.status(500).send({
        error: 'Plan-week failed',
        message: err instanceof Error ? err.message : String(err),
      });
    }
  });
}
