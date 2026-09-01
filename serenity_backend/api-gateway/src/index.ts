import http from 'http';
import { createApp } from './app';
import { config } from './config';
import { registerProxies } from './proxy';
import { errorHandler, notFound } from './middleware/errorHandler';

const app = createApp();
const server = http.createServer(app);

// Proxy routes must be registered before the notFound/errorHandler catch-alls,
// otherwise every API request would short-circuit with a 404.
registerProxies(app, server);

app.use(notFound);
app.use(errorHandler);

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
