# Phase 3 — AI Backend (the graded core)

**Stack:** Vercel AI SDK v7 (`ai@7`), OpenRouter (`@openrouter/ai-sdk-provider` 2.10+), Zod, AG-UI over SSE.
**Purpose:** A **custom** chatbot — hand-written orchestration loop, 26 tools, sub-agent delegation, context management — that streams standard AG-UI events to the client.

**Tightly tied to:**
- **Reuses Phase 1 services** — every tool's `execute` calls a Phase 1 service function (same code as the REST controllers).
- **Defines the AG-UI event contract consumed by Phase 4.** The event names and the `renderHint` on tool results (§8) are the seam between backend and client.
- Optional A2UI (Phase 4 appendix) rides on this same SSE stream.

> **The rule that shapes everything:** the assignment forbids pre-built agent frameworks. The AI SDK is a *toolkit* (allowed), but **do not** ship `ToolLoopAgent` or `@openrouter/agent` as the loop — write the loop yourself. That's the thing being graded.

---

## 1. OpenRouter + AI SDK setup

```ts
import { createOpenRouter } from '@openrouter/ai-sdk-provider';
const openrouter = createOpenRouter({ apiKey: process.env.OPENROUTER_API_KEY! });
const model = openrouter.chat('anthropic/claude-sonnet-4'); // vendor/model — swap freely
```

- Match provider major to `ai@7`; on a `specificationVersion` mismatch, align versions.
- **Prompt caching** for the big system prompt + tool schemas: add `providerOptions.openrouter.cacheControl: { type: 'ephemeral' }` on the stable message parts — cheaper/faster on a 26-tool registry.
- **Cancellation is provider-dependent** on OpenRouter (Anthropic/OpenAI stop billing on abort; some don't) — relevant to Phase 4's stop button.
- Do **not** use `@openrouter/agent` (auto loop) — same "framework" trap as `ToolLoopAgent`.

---

## 2. The custom orchestrator loop

Built on `streamText` with your own control points:

```ts
const result = streamText({
  model,
  system: buildSystemPrompt(userPrefs, bookingContext),
  messages: history,                 // loaded from Conversation/Message
  tools: toolRegistry,               // §3
  stopWhen: stepCountIs(20),         // your loop bound
  prepareStep: ({ steps, messages }) => {
    // YOUR context management:
    //  - compact/summarize old tool results once they're consumed
    //  - narrow `activeTools` by phase (browsing vs booking) to cut confusion
    //  - optionally swap model by task complexity
    return { /* messages?, activeTools?, system? */ };
  },
  onFinish: ({ messages }) => persist(conversationId, messages), // UIMessages -> Message rows
});

for await (const part of result.fullStream) emitAgUi(part); // §8
```

Own explicitly: tool registry, action-chaining, sub-agent delegation, context compaction, persistence. Nothing in that list is delegated to a black box.

---

## 3. Tool registry (26 tools)

Each is `tool({ description, inputSchema: <reused Zod schema>, execute })`, and `execute` calls a Phase 1 service. Descriptions must state *what it does, when to use it, what it returns* — that's what drives routing.

**Movie (10):** `searchMovies` · `getMovieDetails` · `getCast` · `getReviews` · `getShowtimes` · `suggestSimilar` · `getTrending` · `getUpcoming` · `listLanguages` · `listGenres`

**Booking (12):** `findTheatres` · `getScreenInfo` · `checkSeatAvailability` · `holdSeats` · `releaseSeats` · `createBooking` · `checkBookingStatus` · `cancelBooking` · `viewBookingHistory` · `startPayment` · `confirmPayment` · `applyPromoCode`

**Profile / support (4):** `getProfile` · `updatePreferences` · `getRecommendations` · `contactSupport`

**+ `delegateToBookingAssistant`** (§5).

Because tools reuse services, the same Zod schema validates a REST body *and* a tool input — define once in `src/schemas`.

---

## 4. Action-chaining

IDs thread through results so multi-step requests connect:

```
searchMovies -> movieId
  -> getShowtimes(movieId) -> showId
    -> checkSeatAvailability(showId) -> seatIds
      -> holdSeats(showId, seatIds) -> holdToken
        -> createBooking(showId, seatIds, holdToken) -> bookingId
          -> startPayment(bookingId) / confirmPayment
```

Return structured objects (not prose) from tools so the next tool — and the client widgets — can consume them.

---

## 5. Sub-agent — "booking assistant"

A **tool whose `execute` runs a second, constrained loop**. No framework; just a nested `streamText` with a focused prompt and only the booking tools.

```ts
delegateToBookingAssistant: tool({
  description: 'Hand off a full booking request (movie + when/where + party size + prefs). Returns held seats + summary.',
  inputSchema: z.object({ request: z.string(), userId: z.string() }),
  execute: async ({ request, userId }) => {
    const inner = streamText({
      model,
      system: BOOKING_AGENT_PROMPT,
      messages: [{ role: 'user', content: request }],
      tools: bookingToolsOnly,
      stopWhen: stepCountIs(12),
    });
    await inner.consumeStream();
    return { showId, heldSeats, holdExpiresAt, totalCost, summary }; // structured
  },
})
```

Emit a nested tool event around this so the UI can show "booking assistant working…". This answers the doc's "delegate complex tasks" requirement.

---

## 6. Context management & persistence

- **Persistence:** `Conversation` + `Message` (from Phase 1 schema). Load prior `Message`s into `messages` at run start; save via `onFinish`. Key by `threadId`.
- **Compaction:** in `prepareStep`, once a tool result has been used, replace verbose payloads with short summaries so a 20+-action conversation stays within budget without losing the thread.
- **Active-tool narrowing:** expose only the relevant tool subset per phase (browsing vs. booking) to reduce mis-routing on long chats.

---

## 7. System prompts

- **Orchestrator:** persona + capabilities overview, when to delegate to the booking assistant, "always chain IDs, never invent them," "confirm before payment," inject user prefs + current booking context.
- **Booking agent:** narrow — "complete this booking: find movie → find show → check seats → hold the best available → report back with a structured result." Booking tools only.

---

## 8. AG-UI emitter (the backend↔client seam)

No first-class AI SDK→AG-UI bridge exists, so you own ~150 lines mapping `fullStream` parts → AG-UI events, written as SSE from `POST /agent/run` (`Content-Type: text/event-stream`, include `threadId`/`runId`).

| AI SDK stream part | AG-UI event(s) |
|---|---|
| run begins | `RUN_STARTED` |
| `text-delta` | `TEXT_MESSAGE_START` / `TEXT_MESSAGE_CONTENT` / `TEXT_MESSAGE_END` |
| `tool-input-start` / `tool-call` | `TOOL_CALL_START` / `TOOL_CALL_ARGS` / `TOOL_CALL_END` |
| `tool-result` | `TOOL_CALL_RESULT` (+ payload) |
| booking-context change | `STATE_SNAPSHOT` / `STATE_DELTA` (JSON-Patch) |
| `finish` | `RUN_FINISHED` |
| `error` | `RUN_ERROR` |

### `renderHint` contract (read by Phase 4)
Every `TOOL_CALL_RESULT` payload carries a `renderHint` so the client picks a native widget instead of dumping JSON:

```
renderHint ∈ { 'movieList' | 'movieCard' | 'showtimes' | 'seatMap'
             | 'bookingSummary' | 'paymentResult' | 'text' }
```

Phase 4 §6 maps each hint → a Flutter widget. Keep this enum in sync across both docs.

---

## 9. Observability (agent)

Every tool call logs `{ correlationId, tool, argsSummary, durationMs, ok }` using the Phase 1 correlation ID. Expose a summary: error rate by type, avg conversation length, per-tool latency. Retries (exponential backoff) wrap transient model/network failures; the payment tools inherit Phase 1's circuit breaker.

---

## 10. Definition of done

- [ ] `curl -N /agent/run` streams AG-UI-shaped SSE.
- [ ] A conversation chains ≥20 actions across turns without losing context.
- [ ] "Book 2 tickets for X at Y tomorrow evening" delegates to the booking assistant and returns held seats.
- [ ] Every `TOOL_CALL_RESULT` carries a valid `renderHint`.
- [ ] Conversations persist and resume by `threadId`.
- [ ] Per-tool logs share the request's correlation ID.

---

## 11. Reference documentation

- AI SDK — docs — https://vercel.com/docs/ai-sdk
- AI SDK Core — Tool Calling (`inputSchema`, `stopWhen`, `prepareStep`) — https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
- AI SDK — Providers & Models — https://ai-sdk.dev/docs/foundations/providers-and-models
- AI SDK 6 (agents, subagents, Agent interface) — https://vercel.com/blog/ai-sdk-6
- AI SDK 5 (stopWhen, prepareStep, message types) — https://vercel.com/blog/ai-sdk-5
- Building AI agents with the AI SDK — https://vercel.com/kb/guide/how-to-build-ai-agents-with-vercel-and-the-ai-sdk
- AI SDK on GitHub / npm — https://github.com/vercel/ai · https://www.npmjs.com/package/ai
- OpenRouter × Vercel AI SDK — https://openrouter.ai/docs/guides/community/vercel-ai-sdk
- `@openrouter/ai-sdk-provider` (GitHub / npm) — https://github.com/OpenRouterTeam/ai-sdk-provider · https://www.npmjs.com/package/@openrouter/ai-sdk-provider
- OpenRouter provider in AI SDK — https://ai-sdk.dev/providers/community-providers/openrouter
- OpenRouter streaming (SSE, cancellation) — https://openrouter.ai/docs/api/reference/streaming
- OpenRouter quickstart — https://openrouter.ai/docs/quickstart
- AG-UI protocol — intro — https://docs.ag-ui.com/introduction
- AG-UI — GitHub — https://github.com/ag-ui-protocol/ag-ui
- AG-UI event types (all ~17) — https://www.copilotkit.ai/blog/master-the-17-ag-ui-event-types-for-building-agents-the-right-way
- Zod — https://zod.dev/
- Phase 1 services (tool targets) — `Phase-1-CRUD-Backend.md`
