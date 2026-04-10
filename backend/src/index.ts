import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './config.js';
import { registerHealthRoute } from './routes/health.js';
import { registerSearchRoute } from './routes/search.js';
import { registerPlanWeekRoute } from './routes/plan-week.js';

async function main(): Promise<void> {
  const app = Fastify({
    logger: {
      level: 'info',
      transport:
        process.env.NODE_ENV !== 'production'
          ? {
              target: 'pino-pretty',
              options: {
                translateTime: 'HH:MM:ss',
                ignore: 'pid,hostname',
              },
            }
          : undefined,
    },
  });

  await app.register(cors, {
    origin: true, // accept any origin for mobile clients
    methods: ['GET', 'POST'],
  });

  await registerHealthRoute(app);
  await registerSearchRoute(app);
  await registerPlanWeekRoute(app);

  app.get('/', async () => ({
    name: 'Recimo API',
    version: '0.1.0',
    endpoints: ['/health', 'POST /api/search', 'POST /api/plan-week'],
  }));

  try {
    await app.listen({ port: config.port, host: '0.0.0.0' });
    app.log.info(`Recimo backend listening on :${config.port}`);
  } catch (err) {
    app.log.error({ err }, 'Failed to start server');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal startup error:', err);
  process.exit(1);
});
