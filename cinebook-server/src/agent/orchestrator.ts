// src/agent/orchestrator.ts
import { streamText, stepCountIs } from 'ai';
import type { ModelMessage } from 'ai';
import { createOpenRouter } from '@openrouter/ai-sdk-provider';
import type { Response } from 'express';
import { buildToolRegistry } from './tools/index.js';
import { buildSystemPrompt } from './prompts.js';
import { loadHistory, saveHistory, ensureConversation } from './conversationService.js';
import {
  createEmitterState,
  emitRunStarted,
  emitRunFinished,
  emitRunError,
  emitTextDelta,
  emitTextEnd,
  emitToolCallStart,
  emitToolCallArgs,
  emitToolCallEnd,
  emitToolCallResult,
} from './aguiEmitter.js';
import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';

export interface RunAgentOptions {
  userId: string;
  role: string;
  message: string;
  threadId?: string;
  res: Response;
}

function getModel() {
  const openrouter = createOpenRouter({ apiKey: process.env.OPENROUTER_API_KEY! });
  return openrouter('anthropic/claude-sonnet-4');
}

/**
 * The main agent runner.
 *
 * Uses a custom streamText loop (no ToolLoopAgent) with prepareStep for
 * active-tool narrowing. Maps fullStream parts to AG-UI SSE events.
 * Persists conversation history via the conversationService.
 */
export async function runAgent(opts: RunAgentOptions): Promise<void> {
  const { userId, role, message, threadId, res } = opts;

  // ── 1. SSE headers ────────────────────────────────────────────────────────
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders();

  // ── 2. Resolve conversation + load history ────────────────────────────────
  const conversationId = await ensureConversation(threadId, userId);
  const emitterState = createEmitterState(conversationId);
  const history: ModelMessage[] = await loadHistory(conversationId);

  // ── 3. Build system prompt with user prefs ────────────────────────────────
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { prefs: true },
  });
  const systemPrompt = buildSystemPrompt(user?.prefs as object | null, null);

  // ── 4. Build full tool registry (26 domain tools + delegation) ────────────
  const toolRegistry = buildToolRegistry({ userId, role });

  const messages: ModelMessage[] = [
    ...history,
    { role: 'user', content: message } as ModelMessage,
  ];

  // ── 5. Emit RUN_STARTED ───────────────────────────────────────────────────
  emitRunStarted(res, emitterState);
  logger.info('orchestrator.start', { userId, conversationId, msgLength: message.length });

  try {
    // ── 6. Custom streamText loop ─────────────────────────────────────────
    const result = streamText({
      model: getModel(),
      system: systemPrompt,
      messages,
      tools: toolRegistry,
      stopWhen: stepCountIs(20),
      /**
       * prepareStep: active-tool narrowing.
       * After 10 steps if no show has been selected yet, restrict the active
       * tool set to browsing-only tools to avoid mutation without context.
       */
      prepareStep: ({ steps }) => {
        if (steps.length > 10 && !emitterState.bookingContext.showId) {
          const { holdSeats, releaseSeats, createBooking, startPayment, confirmPayment, cancelBooking, ...browsingTools } = toolRegistry;
          return { activeTools: Object.keys(browsingTools) as Array<keyof typeof toolRegistry> };
        }
        return {};
      },
      onFinish: async ({ responseMessages }) => {
        const finalMessages = [...messages, ...responseMessages];
        await saveHistory(conversationId, finalMessages as ModelMessage[]);
        logger.info('orchestrator.finish', { conversationId, count: finalMessages.length });
      },
    });

    // ── 7. Map fullStream parts → AG-UI events ────────────────────────────
    for await (const part of result.fullStream) {
      switch (part.type) {
        // Text streaming — ai@7 uses 'text' field, not 'textDelta'
        case 'text-delta':
          emitTextDelta(res, emitterState, part.text);
          break;

        // Tool input lifecycle — ai@7 separates start/delta/end
        case 'tool-input-start':
          emitTextEnd(res, emitterState);
          emitToolCallStart(res, part.id, part.toolName);
          break;

        case 'tool-input-delta':
          emitToolCallArgs(res, part.id, part.delta);
          break;

        case 'tool-input-end':
          emitToolCallEnd(res, part.id);
          break;

        // Tool result — ai@7 uses 'output', 'toolCallId', 'toolName'
        case 'tool-result': {
          const tr = part as { toolCallId: string; toolName: string; output: unknown };
          emitToolCallResult(res, emitterState, tr.toolCallId, tr.toolName, tr.output);
          break;
        }

        case 'error':
          logger.error('orchestrator.streamError', { error: String(part.error) });
          emitRunError(res, emitterState, String(part.error));
          break;

        // Ignored: start, finish, start-step, finish-step, reasoning-*, raw
        default:
          break;
      }
    }

    emitRunFinished(res, emitterState);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown agent error';
    logger.error('orchestrator.error', { userId, conversationId, error: msg });
    emitRunError(res, emitterState, msg);
  } finally {
    res.end();
  }
}
