import http from 'http';
import { Server } from 'socket.io';
import { createApp } from './app';
import { config } from './config';
import { prisma } from './lib/prisma';
import { registerSocket } from './socket';

const app = createApp();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: config.corsOrigin } });

registerSocket(io);

server.listen(config.port, () => {
  console.log(`Chat service listening on :${config.port}`);
});

server.on('error', (err) => {
  console.error('Chat service server error:', err);
  process.exit(1);
});

async function shutdown(signal: string) {
  console.log(`${signal} received, shutting down...`);
  io.close();
  server.close();
  await prisma.$disconnect();
  process.exit(0);
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('unhandledRejection', (reason) => console.error('Unhandled rejection:', reason));
process.on('uncaughtException', (err) => console.error('Uncaught exception:', err));
