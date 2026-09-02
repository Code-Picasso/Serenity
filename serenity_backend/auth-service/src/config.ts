import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '8001', 10),
  jwtSecret: process.env.JWT_SECRET || 'change-me',
  accessExpires: process.env.JWT_ACCESS_EXPIRES || '15m',
  refreshExpires: process.env.JWT_REFRESH_EXPIRES || '30d',
  refreshExpiresMs: 30 * 24 * 60 * 60 * 1000, // kept in sync with JWT_REFRESH_EXPIRES default
  isProduction: process.env.NODE_ENV === 'production',
  appBaseUrl: process.env.APP_BASE_URL || 'http://localhost:8000',
};
