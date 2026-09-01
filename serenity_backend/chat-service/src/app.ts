import express from 'express';
import cors from 'cors';
import path from 'path';
import { config } from './config';
import { errorHandler, notFound } from './middleware/errorHandler';
import chatRoutes from './routes/chat.routes';

export function createApp(): express.Express {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors({ origin: config.corsOrigin }));
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  app.use('/uploads', express.static(path.resolve(config.uploadDir)));

  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', service: 'chat-service', timestamp: new Date().toISOString() }),
  );

  app.use('/', chatRoutes);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}
