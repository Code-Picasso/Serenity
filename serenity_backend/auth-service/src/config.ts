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
  emailVerificationExpiresMs: 24 * 60 * 60 * 1000,
  smtp: {
    host: process.env.SMTP_HOST || '',
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_SECURE === 'true',
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
    from: process.env.SMTP_FROM || process.env.SMTP_USER || 'no-reply@serenity.app',
  },
};
