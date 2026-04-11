import type { FastifyInstance } from 'fastify';
import { config } from '../config.js';

/**
 * GET /api/diagnose
 *
 * Real end-to-end check that actually calls Serper and OpenAI with
 * minimal requests. Use this instead of /health when you want to
 * verify API keys are valid, not just that env vars are set.
 */
export async function registerDiagnoseRoute(app: FastifyInstance): Promise<void> {
  app.get('/api/diagnose', async () => {
    const checks = {
      openai: await checkOpenAI(),
      serper: await checkSerper(),
    };

    return {
      status: checks.openai.ok && checks.serper.ok ? 'ok' : 'degraded',
      checks,
      timestamp: new Date().toISOString(),
    };
  });
}

async function checkOpenAI(): Promise<{ ok: boolean; error?: string; latencyMs?: number }> {
  if (!config.openaiApiKey) {
    return { ok: false, error: 'OPENAI_API_KEY not set' };
  }

  const started = Date.now();
  try {
    // Cheapest possible OpenAI call: list models
    const response = await fetch('https://api.openai.com/v1/models', {
      headers: {
        Authorization: `Bearer ${config.openaiApiKey}`,
      },
    });

    const latency = Date.now() - started;

    if (response.ok) {
      return { ok: true, latencyMs: latency };
    }

    const body = await response.text().catch(() => '');
    return {
      ok: false,
      error: `OpenAI ${response.status}: ${body.slice(0, 200)}`,
      latencyMs: latency,
    };
  } catch (err) {
    return {
      ok: false,
      error: err instanceof Error ? err.message : String(err),
      latencyMs: Date.now() - started,
    };
  }
}

async function checkSerper(): Promise<{ ok: boolean; error?: string; latencyMs?: number }> {
  if (!config.serperApiKey) {
    return { ok: false, error: 'SERPER_API_KEY not set' };
  }

  const started = Date.now();
  try {
    const response = await fetch('https://google.serper.dev/search', {
      method: 'POST',
      headers: {
        'X-API-KEY': config.serperApiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ q: 'test', num: 1 }),
    });

    const latency = Date.now() - started;

    if (response.ok) {
      return { ok: true, latencyMs: latency };
    }

    const body = await response.text().catch(() => '');
    let friendly = `Serper ${response.status}: ${body.slice(0, 200)}`;
    if (response.status === 403 || response.status === 401) {
      friendly =
        'Serper API key is invalid (403 Unauthorized). ' +
        'Check that SERPER_API_KEY in Railway is correct — no quotes, no whitespace.';
    }
    return {
      ok: false,
      error: friendly,
      latencyMs: latency,
    };
  } catch (err) {
    return {
      ok: false,
      error: err instanceof Error ? err.message : String(err),
      latencyMs: Date.now() - started,
    };
  }
}
