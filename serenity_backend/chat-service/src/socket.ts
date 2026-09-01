import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { config } from './config';
import { chatService } from './services/chat.service';

const room = (conversationId: string) => `conversation:${conversationId}`;

export function registerSocket(io: Server): void {
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      next(new Error('Unauthorized'));
      return;
    }
    try {
      const payload = jwt.verify(token, config.jwtSecret) as { sub: string };
      socket.data.userId = payload.sub;
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const userId = socket.data.userId as string;
    socket.join(`user:${userId}`);
    socket.emit('connected', { userId });

    socket.on('conversation:join', (conversationId: string) => {
      socket.join(room(conversationId));
    });

    socket.on('conversation:send', async (payload, ack) => {
      try {
        const { conversationId, content, type = 'text' } = payload ?? {};
        const result = await chatService.sendMessage(userId, conversationId, type, content, null);
        socket.join(room(conversationId));
        for (const pid of result.participantUserIds) {
          io.to(`user:${pid}`).emit('conversation:message', result.message);
        }
        ack?.({ ok: true, message: result.message });
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to send message';
        ack?.({ ok: false, error: message });
      }
    });

    socket.on('conversation:typing', (payload) => {
      const { conversationId, isTyping } = payload ?? {};
      socket.to(room(conversationId)).emit('conversation:typing', { conversationId, userId, isTyping });
    });

    socket.on('conversation:read', async (payload) => {
      const { conversationId } = payload ?? {};
      await chatService.markRead(userId, conversationId);
      socket.to(room(conversationId)).emit('conversation:read', { conversationId, userId });
    });
  });
}
