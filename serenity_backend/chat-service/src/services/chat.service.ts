import { prisma } from '../lib/prisma';
import { NotFoundError, ValidationError } from '../utils/errors';

export interface ChatMessage {
  id: string;
  conversationId: string;
  senderId: string;
  type: string;
  content: string | null;
  mediaUrl: string | null;
  createdAt: Date;
}

export interface SendMessageResult {
  message: ChatMessage;
  participantUserIds: string[];
}

async function assertParticipant(userId: string, conversationId: string) {
  const participant = await prisma.participant.findUnique({
    where: { conversationId_userId: { conversationId, userId } },
  });
  if (!participant) {
    throw new NotFoundError('Conversation not found or you are not a participant');
  }
  return participant;
}

export const chatService = {
  async listConversations(userId: string) {
    const conversations = await prisma.conversation.findMany({
      where: { participants: { some: { userId } } },
      include: {
        participants: true,
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { updatedAt: 'desc' },
    });
    return conversations.map((c) => ({
      id: c.id,
      isGroup: c.isGroup,
      name: c.name,
      participants: c.participants.map((p) => ({ userId: p.userId, lastReadAt: p.lastReadAt })),
      lastMessage: c.messages[0] ?? null,
      updatedAt: c.updatedAt,
    }));
  },

  async getOrCreateDirect(userId: string, otherUserId: string): Promise<string> {
    if (!otherUserId) throw new ValidationError('userId is required');
    if (userId === otherUserId) throw new ValidationError('Cannot start a conversation with yourself');

    const existing = await prisma.conversation.findMany({
      where: { isGroup: false, participants: { some: { userId } } },
      include: { participants: true },
    });
    const found = existing.find(
      (c) => c.participants.length === 2 && c.participants.some((p) => p.userId === otherUserId),
    );
    if (found) return found.id;

    const created = await prisma.conversation.create({
      data: {
        isGroup: false,
        participants: { create: [{ userId }, { userId: otherUserId }] },
      },
    });
    return created.id;
  },

  async getConversation(userId: string, conversationId: string) {
    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { participants: true },
    });
    if (!conversation) throw new NotFoundError('Conversation not found');
    if (!conversation.participants.some((p) => p.userId === userId)) {
      throw new NotFoundError('You are not a participant');
    }
    return {
      id: conversation.id,
      isGroup: conversation.isGroup,
      name: conversation.name,
      participants: conversation.participants.map((p) => ({ userId: p.userId, lastReadAt: p.lastReadAt })),
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
    };
  },

  async listMessages(userId: string, conversationId: string, page = 1, limit = 50) {
    await assertParticipant(userId, conversationId);
    const skip = (Math.max(page, 1) - 1) * limit;
    const [messages, total] = await Promise.all([
      prisma.message.findMany({
        where: { conversationId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.message.count({ where: { conversationId } }),
    ]);
    return { items: messages.reverse(), page, limit, total };
  },

  async sendMessage(
    userId: string,
    conversationId: string,
    type: 'text' | 'audio' | 'image' = 'text',
    content: string | null,
    mediaUrl: string | null,
  ): Promise<SendMessageResult> {
    await assertParticipant(userId, conversationId);
    if (type === 'text' && !content) throw new ValidationError('content is required for text messages');
    if (type !== 'text' && !mediaUrl) throw new ValidationError('mediaUrl is required for media messages');

    const message = await prisma.message.create({
      data: { conversationId, senderId: userId, type, content, mediaUrl },
    });
    await prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });
    const participants = await prisma.participant.findMany({ where: { conversationId } });
    return { message, participantUserIds: participants.map((p) => p.userId) };
  },

  async markRead(userId: string, conversationId: string) {
    const participant = await assertParticipant(userId, conversationId);
    await prisma.participant.update({
      where: { id: participant.id },
      data: { lastReadAt: new Date() },
    });
    return { success: true };
  },
};
