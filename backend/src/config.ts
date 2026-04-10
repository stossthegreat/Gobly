// Centralized environment configuration — fails fast on missing required vars.

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

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
  openaiApiKey: required('OPENAI_API_KEY'),
  openaiModel: optional('OPENAI_MODEL', 'gpt-4o-mini'),
  serperApiKey: required('SERPER_API_KEY'),
  cacheTtlSeconds: optionalInt('CACHE_TTL_SECONDS', 3600),
  maxCandidates: optionalInt('MAX_CANDIDATES', 6),
  resultsPerQuery: optionalInt('RESULTS_PER_QUERY', 3),
};
