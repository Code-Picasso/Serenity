import express from 'express';
import cors from 'cors';
import { errorHandler, notFound } from './middleware/errorHandler';
import authRoutes from './routes/auth.routes';

export function createApp(): express.Express {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors({ origin: '*' }));
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', service: 'auth-service', timestamp: new Date().toISOString() }),
  );

  app.use('/', authRoutes);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}
