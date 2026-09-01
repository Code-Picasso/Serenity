import jwt, { SignOptions } from 'jsonwebtoken';
import { config } from '../config';

export interface TokenUser {
  id: string;
  email: string;
  name: string;
}

export interface AccessTokenPayload {
  sub: string;
  email: string;
  name: string;
}

export interface RefreshTokenPayload {
  sub: string;
  type: 'refresh';
}

export function signAccessToken(user: TokenUser): string {
  const payload: AccessTokenPayload = { sub: user.id, email: user.email, name: user.name };
  return jwt.sign(payload, config.jwtSecret, { expiresIn: config.accessExpires } as SignOptions);
}

export function signRefreshToken(user: TokenUser): string {
  const payload: RefreshTokenPayload = { sub: user.id, type: 'refresh' };
  return jwt.sign(payload, config.jwtSecret, { expiresIn: config.refreshExpires } as SignOptions);
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  return jwt.verify(token, config.jwtSecret) as RefreshTokenPayload;
}

/** Returns the epoch-ms expiry of a signed token (for persisting a matching TTL). */
export function tokenExpiryMs(token: string): number {
  const decoded = jwt.decode(token) as { exp?: number } | null;
  return (decoded?.exp ?? Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60) * 1000;
}
