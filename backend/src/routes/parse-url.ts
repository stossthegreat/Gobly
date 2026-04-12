import type { FastifyInstance } from 'fastify';
import type { Recipe } from '../types/recipe.js';
import { fetchParallel } from '../services/fetcher.js';
import { extractRecipeFromHtml } from '../services/jsonld.js';

interface ParseUrlRequest {
  url: string;
}

/**
 * POST /api/parse-url
 *
 * Fetches a single URL, extracts the Recipe JSON-LD, and returns
 * the full structured recipe. Used by the "Paste URL" flow so
 * users can save any recipe page with one tap.
 */
export async function registerParseUrlRoute(app: FastifyInstance): Promise<void> {
  app.post<{ Body: ParseUrlRequest }>('/api/parse-url', async (request, reply) => {
    const { url } = request.body;

    if (!url || typeof url !== 'string' || !url.startsWith('http')) {
      return reply.status(400).send({ error: 'A valid URL is required' });
    }

    const started = Date.now();

    try {
      const [result] = await fetchParallel([url]);

      if (!result.html) {
        return reply.status(422).send({
          error: 'Could not fetch the page',
          message: result.error || 'Page returned no content',
        });
      }

      const recipe = extractRecipeFromHtml(result.html, url);

      if (!recipe) {
        return reply.status(422).send({
          error: 'No recipe found on this page',
          message:
            'The page was fetched but no structured recipe data was found. ' +
            'This site may not use the standard recipe format.',
        });
      }

      return {
        recipe,
        durationMs: Date.now() - started,
      };
    } catch (err) {
      app.log.error({ err }, 'parse-url failed');
      return reply.status(500).send({
        error: 'Failed to parse URL',
        message: err instanceof Error ? err.message : String(err),
      });
    }
  });
}
