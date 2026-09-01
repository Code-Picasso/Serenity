import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';

export interface AuthPayload {
  sub: string;
  email: string;
  name?: string;
}

/**
 * Paths that do not require a bearer token. The gateway is the security
 * boundary: protected routes have their JWT verified here and the verified
 * user id/email is injected as trusted headers for downstream services.
 */
const PUBLIC_PATHS = [
  '/',
  '/health',
  '/docs',
  '/openapi',
  '/openapi.yaml',
  '/socket.io',
  '/auth/register',
  '/auth/login',
  '/auth/refresh',
  '/auth/forgot-password',
  '/auth/reset-password',
];

function isPublic(path: string): boolean {
  if (path === '/') return true;
  return PUBLIC_PATHS.some((p) => path === p || path.startsWith(`${p}/`));
}

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  if (isPublic(req.path)) {
    next();
    return;
  }

  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized', message: 'Missing access token' });
    return;
  }

  try {
    const token = header.slice('Bearer '.length);
    const payload = jwt.verify(token, config.jwtSecret) as AuthPayload;
    req.headers['x-user-id'] = payload.sub;
    req.headers['x-user-email'] = payload.email || '';
    req.headers['x-user-name'] = payload.name || '';
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized', message: 'Invalid or expired access token' });
  }
}
