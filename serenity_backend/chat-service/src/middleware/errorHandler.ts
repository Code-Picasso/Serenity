import { NextFunction, Request, Response } from 'express';
import { AppError } from '../utils/errors';

export function notFound(req: Request, res: Response): void {
  res.status(404).json({ error: 'Not Found', message: `Route ${req.method} ${req.originalUrl} does not exist` });
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction): void {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({ error: err.name, message: err.message });
    return;
  }
  console.error('[chat:error]', err);
  res.status(500).json({ error: 'Internal Server Error', message: 'An unexpected error occurred' });
}
