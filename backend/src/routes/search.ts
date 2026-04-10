import type { FastifyInstance } from 'fastify';
import type { Recipe, SearchRequest, SearchResponse } from '../types/recipe.js';
import { serperSearch } from '../services/serper.js';
import { fetchParallel } from '../services/fetcher.js';
import { extractRecipeFromHtml } from '../services/jsonld.js';
import { normalizeQuery } from '../services/openai.js';
import { rankRecipes, filterQuality } from '../services/ranker.js';
import { isBlocked, getDomainInfo, TRUSTED_DOMAINS } from '../data/domains.js';
import { TtlCache } from '../lib/cache.js';
import { config } from '../config.js';

const cache = new TtlCache<SearchResponse>(config.cacheTtlSeconds);

/**
 * POST /api/search
 *
 * The core recipe discovery pipeline:
 * 1. Normalize the user query with GPT-4o mini
 * 2. Search the web via Serper.dev
 * 3. Filter to trusted domains (or at least not blocked)
 * 4. Fetch top candidates in parallel
 * 5. Extract JSON-LD Recipe schema from each
 * 6. Filter low-quality results
 * 7. Rank and return top N
 */
export async function registerSearchRoute(app: FastifyInstance): Promise<void> {
  app.post<{ Body: SearchRequest }>('/api/search', async (request, reply) => {
    const { query, userContext } = request.body;

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return reply.status(400).send({ error: 'Query is required' });
    }

    const normalized = query.trim().toLowerCase();
    const cacheKey = `${normalized}:${userContext || ''}`;

    // Check cache first
    const cached = cache.get(cacheKey);
    if (cached) {
      return { ...cached, cached: true };
    }

    const started = Date.now();

    try {
      // Step 1: Normalize query with LLM
      let searchQuery: string;
      try {
        searchQuery = await normalizeQuery(query, userContext);
      } catch (err) {
        app.log.warn({ err }, 'Query normalization failed, using raw query');
        searchQuery = query;
      }

      // Step 2: Web search
      const searchResults = await serperSearch(searchQuery, 12);

      // Step 3: Filter candidates
      const candidates = searchResults
        .filter((r) => r.link && !isBlocked(r.link))
        .sort((a, b) => {
          // Prefer trusted domains
          const aTrusted = isTrusted(a.link) ? 1 : 0;
          const bTrusted = isTrusted(b.link) ? 1 : 0;
          return bTrusted - aTrusted;
        })
        .slice(0, config.maxCandidates);

      if (candidates.length === 0) {
        return reply.status(404).send({ error: 'No usable results found', query });
      }

      // Step 4: Parallel fetch
      const fetched = await fetchParallel(candidates.map((c) => c.link));

      // Step 5: Extract recipes
      const recipes: Recipe[] = [];
      for (const result of fetched) {
        if (!result.html) continue;
        const recipe = extractRecipeFromHtml(result.html, result.url);
        if (recipe) recipes.push(recipe);
      }

      // Step 6 & 7: Filter quality and rank
      const filtered = filterQuality(recipes, { minImage: true });
      const ranked = rankRecipes(filtered).slice(0, config.resultsPerQuery);

      const response: SearchResponse = {
        query: searchQuery,
        results: ranked,
        durationMs: Date.now() - started,
        cached: false,
      };

      // Only cache if we got good results
      if (ranked.length > 0) {
        cache.set(cacheKey, response);
      }

      return response;
    } catch (err) {
      app.log.error({ err }, 'Search pipeline failed');
      return reply.status(500).send({
        error: 'Search failed',
        message: err instanceof Error ? err.message : String(err),
      });
    }
  });
}

function isTrusted(url: string): boolean {
  const info = getDomainInfo(url);
  return info.domain in TRUSTED_DOMAINS;
}
