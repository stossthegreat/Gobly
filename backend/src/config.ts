// Centralized environment configuration.
// API keys are optional at boot so the server starts cleanly on Railway
// and the health check passes before you add credentials. Endpoints that
// need the keys will throw a clear error at request time if they're missing.

function optional(name: string, fallback: string): string {
  return process.env[name] || fallback;
}

function optionalInt(name: string, fallback: number): number {
  const value = process.env[name];
  if (!value) return fallback;
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? fallback : parsed;
}

export const config = {
  port: optionalInt('PORT', 3000),
  openaiApiKey: optional('OPENAI_API_KEY', ''),
  openaiModel: optional('OPENAI_MODEL', 'gpt-4o-mini'),
  serperApiKey: optional('SERPER_API_KEY', ''),
  cacheTtlSeconds: optionalInt('CACHE_TTL_SECONDS', 3600),
  maxCandidates: optionalInt('MAX_CANDIDATES', 6),
  resultsPerQuery: optionalInt('RESULTS_PER_QUERY', 3),
};

export function assertKeysConfigured(): void {
  const missing: string[] = [];
  if (!config.openaiApiKey) missing.push('OPENAI_API_KEY');
  if (!config.serperApiKey) missing.push('SERPER_API_KEY');
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}. ` +
        'Set them in Railway dashboard under Variables.',
    );
  }
}

/** Returns a status object for the /health endpoint */
export function configStatus(): {
  ok: boolean;
  openaiConfigured: boolean;
  serperConfigured: boolean;
} {
  return {
    ok: true,
    openaiConfigured: !!config.openaiApiKey,
    serperConfigured: !!config.serperApiKey,
  };
}
