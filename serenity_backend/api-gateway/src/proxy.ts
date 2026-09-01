import { Express } from 'express';
import http from 'http';
import { createProxyMiddleware, Options } from 'http-proxy-middleware';
import { config } from './config';

interface ProxyRule {
  path: string;
  target: string;
  rewrite?: string;
  ws?: boolean;
}

const rules: ProxyRule[] = [
  // WebSocket (Socket.IO) traffic goes straight to the chat service. Auth is
  // verified by the chat service itself using the token in the handshake auth.
  { path: '/socket.io', target: config.services.chat, ws: true },
  { path: '/auth', target: config.services.auth, rewrite: '^/auth' },
  { path: '/chat', target: config.services.chat, rewrite: '^/chat' },
  { path: '/feed', target: config.services.feed, rewrite: '^/feed' },
  { path: '/posts', target: config.services.post, rewrite: '^/posts' },
  { path: '/users', target: config.services.user, rewrite: '^/users' },
  { path: '/notifications', target: config.services.notification, rewrite: '^/notifications' },
];

export function registerProxies(app: Express, server?: http.Server): void {
  for (const rule of rules) {
    const options: Options = {
      target: rule.target,
      changeOrigin: true,
      ws: rule.ws ?? false,
      on: {
        error: (err, _req, res) => {
          console.error(`[gateway:proxy] ${rule.path} -> ${rule.target} failed:`, err.message);
          const response = res as unknown as http.ServerResponse;
          if (response && !response.headersSent) {
            response.writeHead(502, { 'Content-Type': 'application/json' });
            response.end(JSON.stringify({ error: 'Bad Gateway', message: 'Upstream service unavailable' }));
          }
        },
      },
    };
    if (rule.rewrite) {
      options.pathRewrite = { [rule.rewrite]: '' };
    }
    const middleware = createProxyMiddleware(options);
    app.use(rule.path, middleware);
    if (rule.ws && server) {
      server.on('upgrade', middleware.upgrade as never);
    }
  }
}
