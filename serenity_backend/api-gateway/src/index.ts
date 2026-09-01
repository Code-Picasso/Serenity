import http from 'http';
import { createApp } from './app';
import { config } from './config';
import { registerProxies } from './proxy';

const app = createApp();
const server = http.createServer(app);

// Re-register proxies with the server reference so WebSocket upgrades work.
registerProxies(app, server);

server.listen(config.port, () => {
  console.log(`Serenity API Gateway listening on :${config.port}`);
});

server.on('error', (err) => {
  console.error('Gateway server error:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled promise rejection:', reason);
});
process.on('uncaughtException', (err) => {
  console.error('Uncaught exception:', err);
});
