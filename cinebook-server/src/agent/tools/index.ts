// src/agent/tools/index.ts
import { movieTools } from './movieTools.js';
import { createBookingTools } from './bookingTools.js';
import { createProfileTools } from './profileTools.js';
import { delegateToBookingAssistant } from '../bookingAgent.js';

export type ToolContext = { userId: string; role: string; city?: string };

/**
 * Full tool registry: 10 movie + 12 booking + 4 profile + 1 delegation = 27 tools.
 * Bound to the authenticated user's context.
 */
export function buildToolRegistry(ctx: ToolContext) {
  return {
    ...movieTools,
    ...createBookingTools(ctx.userId, ctx.role),
    ...createProfileTools(ctx.userId),
    delegateToBookingAssistant: delegateToBookingAssistant(ctx),
  };
}

/**
 * Booking-only subset for the nested booking sub-agent.
 * Excludes delegation to prevent infinite nesting.
 */
export function buildBookingToolsOnly(ctx: ToolContext) {
  return createBookingTools(ctx.userId, ctx.role);
}
