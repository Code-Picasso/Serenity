import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import { authMiddleware } from './middleware/auth';
import { setupSwagger } from './swagger';

export function createApp(): express.Express {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors({ origin: '*', credentials: true }));
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true }));

  app.use(
    rateLimit({
      windowMs: config.rateLimit.windowMs,
      max: config.rateLimit.max,
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', service: 'api-gateway', timestamp: new Date().toISOString() }),
  );
  app.get('/', (_req, res) =>
    res.json({ service: 'Serenity API Gateway', docs: '/docs', health: '/health' }),
  );

  setupSwagger(app);

  app.use(authMiddleware);

  return app;
}
