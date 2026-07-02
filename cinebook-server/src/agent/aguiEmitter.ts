// src/agent/aguiEmitter.ts
import type { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';

/** Mutable state shared across one agent run's event emission. */
export interface AgentEmitterState {
  runId: string;
  threadId: string;
  /** ID of the currently open TEXT_MESSAGE, or null if no text is streaming. */
  currentTextMessageId: string | null;
  /** Accumulated booking context (showId, holdToken, etc.) for STATE_SNAPSHOT events. */
  bookingContext: Record<string, unknown>;
}

export function createEmitterState(threadId: string): AgentEmitterState {
  return {
    runId: uuidv4(),
    threadId,
    currentTextMessageId: null,
    bookingContext: {},
  };
}

/** Write a single SSE data frame. */
function writeEvent(res: Response, event: Record<string, unknown>): void {
  res.write(`data: ${JSON.stringify(event)}\n\n`);
}

// ─── Public emitters ──────────────────────────────────────────────────────────

export function emitRunStarted(res: Response, state: AgentEmitterState): void {
  writeEvent(res, { type: 'RUN_STARTED', runId: state.runId, threadId: state.threadId });
}

export function emitRunFinished(res: Response, state: AgentEmitterState): void {
  // Close any open text message before finishing
  if (state.currentTextMessageId) {
    writeEvent(res, { type: 'TEXT_MESSAGE_END', messageId: state.currentTextMessageId });
    state.currentTextMessageId = null;
  }
  writeEvent(res, { type: 'RUN_FINISHED', runId: state.runId, threadId: state.threadId });
}

export function emitRunError(res: Response, state: AgentEmitterState, message: string): void {
  writeEvent(res, { type: 'RUN_ERROR', runId: state.runId, threadId: state.threadId, message });
}

export function emitTextDelta(res: Response, state: AgentEmitterState, delta: string): void {
  if (!state.currentTextMessageId) {
    state.currentTextMessageId = uuidv4();
    writeEvent(res, { type: 'TEXT_MESSAGE_START', messageId: state.currentTextMessageId });
  }
  writeEvent(res, { type: 'TEXT_MESSAGE_CONTENT', messageId: state.currentTextMessageId, delta });
}

export function emitTextEnd(res: Response, state: AgentEmitterState): void {
  if (state.currentTextMessageId) {
    writeEvent(res, { type: 'TEXT_MESSAGE_END', messageId: state.currentTextMessageId });
    state.currentTextMessageId = null;
  }
}

export function emitToolCallStart(res: Response, toolCallId: string, toolName: string): void {
  writeEvent(res, { type: 'TOOL_CALL_START', toolCallId, toolCallName: toolName || 'tool' });
}

export function emitToolCallArgs(res: Response, toolCallId: string, delta: string): void {
  writeEvent(res, { type: 'TOOL_CALL_ARGS', toolCallId, delta });
}

export function emitToolCallEnd(res: Response, toolCallId: string): void {
  writeEvent(res, { type: 'TOOL_CALL_END', toolCallId });
}

/**
 * Emit the tool result event and, if relevant booking fields are present,
 * also emit a STATE_SNAPSHOT to update the client's booking context.
 */
export function emitToolCallResult(
  res: Response,
  state: AgentEmitterState,
  toolCallId: string,
  toolName: string,
  result: unknown
): void {
  writeEvent(res, { 
    type: 'TOOL_CALL_RESULT', 
    messageId: toolCallId, 
    toolCallId, 
    content: JSON.stringify(result) 
  });

  // Extract booking state fields and emit STATE_SNAPSHOT if anything changed
  const r = result as Record<string, unknown>;
  const bookingFields = ['bookingId', 'holdToken', 'showId', 'heldSeatIds'];
  let changed = false;
  for (const field of bookingFields) {
    if (r[field] !== undefined) {
      state.bookingContext[field] = r[field];
      changed = true;
    }
  }
  if (changed) {
    writeEvent(res, { type: 'STATE_SNAPSHOT', snapshot: { ...state.bookingContext } });
  }
}
