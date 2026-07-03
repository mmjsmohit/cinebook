// src/agent/bookingAgent.ts
import { tool, streamText, stepCountIs } from 'ai';
import { createOpenRouter } from '@openrouter/ai-sdk-provider';
import { delegateSchema } from '../schemas/index.js';
import { buildBookingToolsOnly, type ToolContext } from './tools/index.js';
import { buildBookingAgentPrompt } from './prompts.js';
import { withToolLogger } from './toolLogger.js';
import { logger } from '../infra/logger.js';
import { prisma } from '../db.js';
import { CATEGORY_MULTIPLIER } from '../services/movieService.js';
import type { SeatCategory } from '@prisma/client';

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
        system: buildBookingAgentPrompt(
          ctx.city 
            ? { city: ctx.city, currentTime: new Date().toISOString() } 
            : { currentTime: new Date().toISOString() }
        ),
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
      
      let totalCost = 0;
      let movieTitle = '';
      if (showId && heldSeats.length > 0) {
        const show = await prisma.show.findUnique({
          where: { id: showId },
          include: { 
            movie: true,
            screen: { include: { seats: { where: { id: { in: heldSeats } } } } } 
          }
        });
        if (show) {
          movieTitle = show.movie.title;
          totalCost = show.screen.seats.reduce((sum, seat) => {
            return sum + Math.round(show.basePrice * CATEGORY_MULTIPLIER[seat.category as SeatCategory]);
          }, 0);
        }
      }

      logger.info('bookingAgent.complete', { userId: ctx.userId, showId, heldCount: heldSeats.length, totalCost });

      return {
        renderHint: 'bookingSummary' as const,
        showId,
        heldSeatIds: heldSeats,
        holdToken,
        expiresAt,
        summary,
        totalCost,
        movieTitle,
      };
    }),
  });
}
