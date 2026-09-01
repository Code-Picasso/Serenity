import { Request, Response } from 'express';
import { chatService } from '../services/chat.service';

function userIdFrom(req: Request): string {
  const id = req.headers['x-user-id'];
  if (!id || Array.isArray(id)) {
    throw new Error('Missing x-user-id header (gateway should provide it)');
  }
  return id;
}

function intQuery(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : fallback;
}

export const chatController = {
  listConversations: (req: Request, res: Response) =>
    chatService.listConversations(userIdFrom(req)).then((r) => res.json(r)),

  createConversation: (req: Request, res: Response) =>
    chatService.getOrCreateDirect(userIdFrom(req), req.body?.userId).then((id) => res.status(201).json({ id })),

  getConversation: (req: Request, res: Response) =>
    chatService.getConversation(userIdFrom(req), req.params.id).then((r) => res.json(r)),

  listMessages: (req: Request, res: Response) =>
    chatService
      .listMessages(userIdFrom(req), req.params.id, intQuery(req.query.page, 1), intQuery(req.query.limit, 50))
      .then((r) => res.json(r)),

  sendMessage: (req: Request, res: Response) =>
    chatService
      .sendMessage(userIdFrom(req), req.params.id, req.body?.type ?? 'text', req.body?.content ?? null, req.body?.mediaUrl ?? null)
      .then((r) => res.status(201).json(r.message)),

  sendAudioMessage: (req: Request, res: Response) => {
    const file = req.file;
    if (!file) {
      res.status(400).json({ error: 'ValidationError', message: 'audio file is required' });
      return;
    }
    const mediaUrl = `/chat/uploads/${file.filename}`;
    return chatService
      .sendMessage(userIdFrom(req), req.params.id, 'audio', null, mediaUrl)
      .then((r) => res.status(201).json(r.message));
  },

  markRead: (req: Request, res: Response) =>
    chatService.markRead(userIdFrom(req), req.params.id).then((r) => res.json(r)),
};
