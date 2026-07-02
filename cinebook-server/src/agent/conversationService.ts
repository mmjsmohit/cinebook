// src/agent/conversationService.ts
import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import type { ModelMessage } from 'ai';

/**
 * Ensure a Conversation row exists for this session.
 * - If threadId is provided and found in DB: returns it (resuming prior chat).
 * - If threadId is absent or not found: creates a new Conversation and returns its id.
 * The returned id is the canonical threadId clients should use for future turns.
 */
export async function ensureConversation(
  threadId: string | undefined,
  userId: string
): Promise<string> {
  if (threadId) {
    const existing = await prisma.conversation.findUnique({ where: { id: threadId } });
    if (existing) {
      logger.info('conversationService.resume', { threadId });
      return existing.id;
    }
  }
  const conv = await prisma.conversation.create({ data: { userId } });
  logger.info('conversationService.created', { conversationId: conv.id, userId });
  return conv.id;
}

/**
 * Load conversation history as ModelMessage[].
 * The `content` JSON column stores the AI SDK ModelMessage content shape verbatim,
 * so we can round-trip it without transformation.
 */
export async function loadHistory(conversationId: string): Promise<ModelMessage[]> {
  const messages = await prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'asc' },
  });
  return messages.map((m) => ({ role: m.role, content: m.content } as unknown as ModelMessage));
}

/**
 * Persist the full updated message history for a conversation.
 * Uses a delete+insert inside a transaction (full replace each turn).
 * Called from the orchestrator's onFinish callback after each agent turn.
 */
export async function saveHistory(
  conversationId: string,
  messages: ModelMessage[]
): Promise<void> {
  await prisma.$transaction(async (tx) => {
    await tx.message.deleteMany({ where: { conversationId } });
    await tx.message.createMany({
      data: messages.map((m) => ({
        conversationId,
        role: m.role,
        content: m.content as object,
      })),
    });
  });
  logger.info('conversationService.saved', { conversationId, count: messages.length });
}

export async function getConversationsForUser(userId: string) {
  return prisma.conversation.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
}

export async function getConversationWithMessages(conversationId: string, userId: string) {
  return prisma.conversation.findFirst({
    where: { id: conversationId, userId },
    include: {
      messages: {
        orderBy: { createdAt: 'asc' },
      },
    },
  });
}
