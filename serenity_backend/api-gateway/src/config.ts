import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '8000', 10),
  jwtSecret: process.env.JWT_SECRET || 'change-me',
  services: {
    auth: process.env.AUTH_SERVICE_URL || 'http://auth-service:8001',
    chat: process.env.CHAT_SERVICE_URL || 'http://chat-service:8002',
    feed: process.env.FEED_SERVICE_URL || 'http://feed-service:8004',
    post: process.env.POST_SERVICE_URL || 'http://post-service:8005',
    user: process.env.USER_SERVICE_URL || 'http://user-service:8006',
    notification: process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:8007',
  },
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX || '300', 10),
  },
};
