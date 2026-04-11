import type { FastifyInstance } from 'fastify';
import { configStatus } from '../config.js';

export async function registerHealthRoute(app: FastifyInstance): Promise<void> {
  app.get('/health', async () => {
    const status = configStatus();
    return {
      status: 'ok',
      service: 'recimo-backend',
      timestamp: new Date().toISOString(),
      config: {
        openaiConfigured: status.openaiConfigured,
        serperConfigured: status.serperConfigured,
        ready: status.openaiConfigured && status.serperConfigured,
      },
    };
  });
}
