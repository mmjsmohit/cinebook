// src/agent/toolLogger.ts
import { logger, als } from '../infra/logger.js';

/**
 * Higher-order function that wraps a tool's execute function with structured observability logging.
 * Emits: { correlationId, tool, argsSummary, durationMs, ok }
 * The correlationId is inherited from the request's AsyncLocalStorage context,
 * so every tool call is traceable to the original HTTP request.
 */
export function withToolLogger<TInput extends object, TOutput>(
  toolName: string,
  fn: (input: TInput) => Promise<TOutput>
): (input: TInput) => Promise<TOutput> {
  return async (input: TInput): Promise<TOutput> => {
    const correlationId = als.getStore()?.correlationId ?? 'agent-no-ctx';
    const argsSummary = JSON.stringify(input).slice(0, 200);
    const start = Date.now();
    try {
      const result = await fn(input);
      logger.info('agent.tool', {
        correlationId,
        tool: toolName,
        argsSummary,
        durationMs: Date.now() - start,
        ok: true,
      });
      return result;
    } catch (err: unknown) {
      logger.error('agent.tool.error', {
        correlationId,
        tool: toolName,
        argsSummary,
        durationMs: Date.now() - start,
        ok: false,
        error: err instanceof Error ? err.message : String(err),
      });
      throw err;
    }
  };
}
