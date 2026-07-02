// src/agent/bookingAgent.ts
import { tool, streamText, stepCountIs } from 'ai';
import { createOpenRouter } from '@openrouter/ai-sdk-provider';
import { delegateSchema } from '../schemas/index.js';
import { buildBookingToolsOnly, type ToolContext } from './tools/index.js';
import { BOOKING_AGENT_SYSTEM_PROMPT } from './prompts.js';
import { withToolLogger } from './toolLogger.js';
import { logger } from '../infra/logger.js';

function getModel() {
  const openrouter = createOpenRouter({ apiKey: process.env.OPENROUTER_API_KEY! });
  return openrouter('google/gemini-3.5-flash');
}

/**
 * Returns the delegateToBookingAssistant tool bound to the user context.
 * The nested streamText loop uses only the 12 booking-domain tools,
 * preventing infinite recursive delegation.
 */
export function delegateToBookingAssistant(ctx: ToolContext) {
  return tool({
    description:
      'Hand off a complete booking request (movie + when/where + party size + preferences) to a specialised booking sub-agent. The sub-agent finds showtimes, picks seats, and holds them — but does NOT complete the booking. Returns: showId, heldSeatIds, holdToken, expiresAt, and a summary. Use when user says e.g. "Book 2 tickets for X at Y tomorrow evening".',
    inputSchema: delegateSchema,
    execute: withToolLogger('delegateToBookingAssistant', async ({ request }) => {
      logger.info('bookingAgent.start', { userId: ctx.userId, request: request.slice(0, 100) });

      const inner = streamText({
        model: getModel(),
        system: BOOKING_AGENT_SYSTEM_PROMPT,
        messages: [{ role: 'user', content: request }],
        tools: buildBookingToolsOnly(ctx),
        stopWhen: stepCountIs(12),
      });

      // Consume the stream to drive execution
      for await (const _chunk of inner.fullStream) {
        // Drain stream — tools execute as side-effects
      }

      // Extract holdSeats result from completed steps
      const steps = await inner.steps;
      let heldSeats: string[] = [];
      let holdToken: string | undefined;
      let expiresAt: string | undefined;
      let showId: string | undefined;

      for (const step of steps) {
        for (const result of step.toolResults) {
          const r = result as { toolName: string; input?: Record<string, unknown>; output?: Record<string, unknown> };
          if (r.toolName === 'holdSeats') {
            if (r.input?.showId) showId = r.input.showId as string;
            if (r.input?.seatIds) heldSeats = r.input.seatIds as string[];
            if (r.output?.holdToken) holdToken = r.output.holdToken as string;
            if (r.output?.expiresAt) expiresAt = r.output.expiresAt as string;
          }
        }
      }

      const summary = await inner.text;
      logger.info('bookingAgent.complete', { userId: ctx.userId, showId, heldCount: heldSeats.length });

      return {
        renderHint: 'bookingSummary' as const,
        showId,
        heldSeatIds: heldSeats,
        holdToken,
        expiresAt,
        summary,
      };
    }),
  });
}
