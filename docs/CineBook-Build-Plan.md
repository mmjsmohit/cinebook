# CineBook — Build Plan & Architecture

AI-powered movie booking platform. This is the build sheet to code against, grounded in the current docs for every technology in the stack (verified July 2026).

---

## 0. Locked decisions

| Concern | Decision |
|---|---|
| Backend | Node 22+, Express, TypeScript |
| ORM / DB | Prisma + PostgreSQL; Redis (node-redis) for holds, rate limits, circuit-breaker state |
| Validation | Zod (single source of truth, shared with tool `inputSchema`) |
| Auth | JWT (access + refresh), simulated phone-OTP, RBAC middleware |
| LLM | Vercel AI SDK v7 (`ai@7`) via OpenRouter (`@openrouter/ai-sdk-provider` 2.10+) — **custom agent loop, not `ToolLoopAgent`/`@openrouter/agent`** |
| Agent → client transport | AG-UI events over SSE (custom emitter mapping AI SDK stream parts → AG-UI event types) |
| Seat status | Polling (`GET /shows/:id/seats`), separate from the chat stream |
| User app | Flutter (Bloc + Material) — customer flows **+ AI chatbot** |
| Hall app | Flutter (Bloc + Material) — separate app, scheduling only |
| Admin | React + Vite (thin, talks to Admin APIs) |
| A2UI | Reserved stretch (§11), not load-bearing |

**Two independent real-time paths** (keep them separate in your head and your code):
1. **Chat path** — event-driven, AG-UI over SSE.
2. **Seat path** — polling + Redis holds + Postgres commit.

---

## 1. Project structure

Four repos/folders (per your "two separate apps, clean separation" call):

```
cinebook-server/       # Express + Prisma + Redis + AI agent
cinebook-admin/        # React + Vite
cinebook-user-app/     # Flutter (customer + chatbot)
cinebook-hall-app/     # Flutter (hall manager)
```

Optional but recommended: a shared Dart package `cinebook_core` (API client, DTO models, auth/token storage) pulled into both Flutter apps via a `path:` dependency. This is shared *plumbing*, not shared UI — it removes duplication without the role-conditional UI mess you wanted to avoid. Skip it if you'd rather not.

Server internal layout (keep services framework-free so the agent and the REST controllers call the *same* logic):

```
src/
  http/            # express routers + controllers (thin)
  services/        # movie, show, booking, payment, hold, promo — pure logic
  agent/
    tools/         # 20+ tool defs (thin wrappers over services)
    orchestrator.ts# your custom loop
    bookingAgent.ts# the sub-agent
    agui-emitter.ts# AI SDK stream -> AG-UI SSE
    prompts.ts
  infra/           # prisma client, redis client, logger, circuit-breaker, rate-limit
  auth/            # jwt, otp, rbac middleware
  schemas/         # zod schemas (reused as tool inputSchema)
```

---

## 2. Environment & versions to pin

- **Node 22+** (hard requirement for `ai@7`).
- `ai@^7`, `@openrouter/ai-sdk-provider@^2.10`, `zod`, `@prisma/client`, `prisma`, `redis`, `express`, `jsonwebtoken`.
- If you hit a `specificationVersion` mismatch between the provider and `ai`, align their versions — the provider must expose provider-spec v2/v3.
- OpenRouter setup:
  ```ts
  import { createOpenRouter } from '@openrouter/ai-sdk-provider';
  const openrouter = createOpenRouter({ apiKey: process.env.OPENROUTER_API_KEY! });
  const model = openrouter.chat('anthropic/claude-sonnet-4'); // vendor/model; swap freely
  ```
- Default to a strong tool-calling model; OpenRouter lets you switch by string. Cache the system prompt + tool schemas with `providerOptions.openrouter.cacheControl: { type: 'ephemeral' }`.

---

## 3. Data model (Prisma sketch)

Covers all 13 required entities plus Review, PromoCode, and chat persistence.

```prisma
enum Role { CUSTOMER HALL_MANAGER ADMIN }
enum SeatCategory { FRONT STANDARD PREMIUM RECLINER }
enum ScreenType { STANDARD IMAX FOURDX DOLBY_ATMOS }
enum BookingStatus { PENDING CONFIRMED CANCELLED }
enum PaymentStatus { PENDING SUCCESS FAILED REFUNDED }

model User {
  id        String   @id @default(cuid())
  phone     String   @unique
  name      String?
  role      Role     @default(CUSTOMER)
  disabled  Boolean  @default(false)
  managedScreens Screen[] @relation("ScreenManager")
  bookings  Booking[]
  prefs     Json?    // language, seat category, favourite genres
  createdAt DateTime @default(now())
}

model Movie {
  id          String   @id @default(cuid())
  title       String
  description String
  runtimeMin  Int
  cast        String[]
  posterUrl   String?
  trailerUrl  String?
  releaseDate DateTime
  ageRating   String   // U | UA | A
  languages   String[]
  genres      Genre[]  @relation("MovieGenres")
  reviews     Review[]
  shows       Show[]
}

model Genre { id String @id @default(cuid()) name String @unique movies Movie[] @relation("MovieGenres") }
model Review { id String @id @default(cuid()) movieId String movie Movie @relation(fields:[movieId],references:[id]) rating Int author String body String }

model Theatre {
  id      String @id @default(cuid())
  chain   String // PVR | INOX | Cinepolis
  name    String
  city    String
  address String
  screens Screen[]
}

model Screen {
  id         String     @id @default(cuid())
  theatreId  String
  theatre    Theatre    @relation(fields:[theatreId],references:[id])
  name       String
  type       ScreenType
  format     String     // 2D | 3D
  equipment  String[]
  managerId  String?
  manager    User?      @relation("ScreenManager", fields:[managerId], references:[id])
  seats      Seat[]
  shows      Show[]
}

model Seat {
  id       String       @id @default(cuid())
  screenId String
  screen   Screen       @relation(fields:[screenId],references:[id])
  row      String
  number   Int
  category SeatCategory
  @@unique([screenId, row, number])
}

model Show {
  id        String   @id @default(cuid())
  movieId   String
  screenId  String
  movie     Movie    @relation(fields:[movieId],references:[id])
  screen    Screen   @relation(fields:[screenId],references:[id])
  startTime DateTime
  endTime   DateTime
  basePrice Int      // paise; per-seat = base * category multiplier
  language  String
  format    String
  bookedSeats BookedSeat[]
  @@index([screenId, startTime])
}

model Booking {
  id          String        @id @default(cuid())
  userId      String
  showId      String
  user        User          @relation(fields:[userId],references:[id])
  status      BookingStatus @default(PENDING)
  totalCost   Int
  seats       BookedSeat[]
  payment     Payment?
  createdAt   DateTime      @default(now())
}

model BookedSeat {
  id        String  @id @default(cuid())
  bookingId String
  showId    String
  seatId    String
  pricePaid Int
  booking   Booking @relation(fields:[bookingId],references:[id])
  show      Show    @relation(fields:[showId],references:[id])
  @@unique([showId, seatId]) // DB-level double-booking guard
}

model Payment {
  id            String        @id @default(cuid())
  bookingId     String        @unique
  amount        Int
  status        PaymentStatus @default(PENDING)
  transactionId String        @unique
  createdAt     DateTime      @default(now())
}

model PromoCode { code String @id percentOff Int active Boolean @default(true) }

model AdminActivityLog {
  id        String   @id @default(cuid())
  actorId   String
  action    String
  entity    String
  metadata  Json?
  createdAt DateTime @default(now())
}

model Conversation { id String @id @default(cuid()) userId String createdAt DateTime @default(now()) messages Message[] }
model Message { id String @id @default(cuid()) conversationId String role String content Json createdAt DateTime @default(now()) conversation Conversation @relation(fields:[conversationId],references:[id]) }
```

> **Seat holds live in Redis, not Postgres** — the doc lists "Seat Holds" as an entity, but you want TTL-based auto-expiry, which Postgres doesn't do natively. The `@@unique([showId, seatId])` on `BookedSeat` is your final consistency guard.

---

## 4. Phase 0 — Foundation

- `docker-compose` with Postgres + Redis. Prisma schema above → `migrate dev` → seed script (theatres, screens, seat layouts, movies, genres, shows, promo codes, a few users per role).
- Zod schemas in `src/schemas` — these become both request validators **and** tool `inputSchema`s later. Do this once, reuse everywhere.
- Auth: `POST /auth/request-otp` (rate-limited, logs a fake code), `POST /auth/verify-otp` → issues access (15m) + refresh (7d) JWT with `role` claim. `POST /auth/refresh`. RBAC middleware `requireRole(...roles)`.
- **Structured logger with a per-request correlation ID from day one** (`req.id` via `als`/AsyncLocalStorage). Part 3 observability is nearly free if you start here and expensive to retrofit.

**Done when:** all three roles can log in, tokens refresh, and a protected route rejects the wrong role.

---

## 5. Phase 1 — CRUD backend + seat concurrency

### CRUD & customer browse
- Movies/genres/theatres/screens/seats/shows read endpoints + filters (release date, genre, chain, screen type, format, language, age rating).
- `GET /shows/:id/seats` → merges DB `BookedSeat` (booked) + Redis holds (held) + computes per-seat price from category → returns colour-coded map state. This is the **polling** endpoint.

### Seat hold + booking + payment (the concurrency core)
This is the pattern from the reference video, in node-redis:

1. **Hold** (`holdSeats`): for each seat, `SET seat:{showId}:{seatId} {ownerToken} NX PX 300000` (5-min TTL). If any `SET` fails → seat taken → release the ones you grabbed, return conflict. `ownerToken = {userId}:{nonce}`.
2. **Release** (`releaseSeats`): Lua **compare-and-delete** — only delete if the value equals your token (never release someone else's hold):
   ```lua
   if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end
   ```
3. **Confirm** (`createBooking`): Postgres transaction — `SELECT ... FOR UPDATE` the show row (or rely on the `@@unique([showId, seatId])` insert + optimistic retry), re-verify each Redis hold is still yours, insert `Booking` + `BookedSeat`s, then release the holds. If the unique insert throws, someone beat you → surface a clean conflict.
4. **Payment** (simulated): test cards → always-pass / always-fail / random-fail; 1–3s artificial delay; unique `transactionId`; `refund()`. Wrap this service in the **circuit breaker** (§10).

### Hall-manager scheduling (business rules, server-enforced)
On create/update of a `Show`, validate and return a **specific** error per broken rule: no overlap on the same screen; ≥30-min gap between shows; ≤30 days ahead; manager owns the screen; **reject edit/delete if any `BookedSeat` exists** for that show. Admin bypasses ownership (override).

**Done when:** two concurrent hold requests for the same seat → exactly one wins; a booked show can't be edited; payment failures behave per card type.

---

## 6. Phase 2 — Flutter apps (both, non-AI)

Shared setup in each app: Bloc, `dio` API client with JWT interceptor + refresh-on-401, `flutter_secure_storage` for tokens ("stay logged in across sessions").

**`cinebook-user-app`:** OTP login → movie list + filters → movie detail → showtimes → **seat map** (polls `GET /shows/:id/seats` every ~2–3s via a Bloc timer; colour-codes free/held/booked; enforces 5-min hold countdown) → payment → confirmation with booking ID. Booking history screen.

**`cinebook-hall-app`:** OTP login → list of assigned screens → show calendar → create/edit/delete show with client-side hints but **server is source of truth** for rule violations (render the specific server error).

**Done when:** a full booking works end-to-end from the customer app with live seat updates, and a hall manager can schedule within the rules.

---

## 7. Phase 3 — AI backend (the graded core)

### 7.1 The custom orchestrator loop
Build the loop yourself on `streamText` — this is what the "no pre-built agent frameworks" rule is testing.

```ts
// pseudo-shape
const result = streamText({
  model,
  system: SYSTEM_PROMPT,            // + user prefs + booking context
  messages: history,               // loaded from Conversation/Message
  tools: toolRegistry,             // §7.2, each tool has inputSchema + execute
  stopWhen: stepCountIs(20),       // your loop bound
  prepareStep: ({ steps, messages }) => {
    // YOUR context management: compact old tool results,
    // narrow active tools by phase (browsing vs booking), etc.
  },
});
for await (const part of result.fullStream) { emitAgUi(part); } // §7.3
```

Own these explicitly (don't delegate to a black box): tool registry, action-chaining (thread IDs through results — searchMovies → movieId → getShowtimes → showId → checkSeatAvailability → …), context compaction in `prepareStep`, and conversation persistence (`onFinish` → save UIMessages to `Message`).

### 7.2 Tool registry (26 tools, all thin wrappers over Phase-1 services)

**Movie (10):** `searchMovies`, `getMovieDetails`, `getCast`, `getReviews`, `getShowtimes`, `suggestSimilar`, `getTrending`, `getUpcoming`, `listLanguages`, `listGenres`
**Booking (12):** `findTheatres`, `getScreenInfo`, `checkSeatAvailability`, `holdSeats`, `releaseSeats`, `createBooking`, `checkBookingStatus`, `cancelBooking`, `viewBookingHistory`, `startPayment`, `confirmPayment`, `applyPromoCode`
**Profile/support (4):** `getProfile`, `updatePreferences`, `getRecommendations`, `contactSupport`

Each: `tool({ description, inputSchema: <reused Zod schema>, execute })`. Descriptions matter for routing — say what it does, when to use it, what it returns.

### 7.3 Sub-agent (delegation) — "booking assistant"
A single tool whose `execute` runs a **second constrained loop**:

```ts
delegateToBookingAssistant: tool({
  description: 'Hand off a complete booking request (movie + when/where + party size + prefs).',
  inputSchema: z.object({ request: z.string(), userId: z.string() }),
  execute: async ({ request, userId }) => {
    const inner = streamText({
      model,
      system: BOOKING_AGENT_PROMPT,          // focused persona
      messages: [{ role: 'user', content: request }],
      tools: bookingToolsOnly,               // subset only
      stopWhen: stepCountIs(12),
    });
    // consume inner stream, return a STRUCTURED result to the orchestrator
    return { heldSeats, showId, holdExpiresAt, summary };
  },
})
```

The orchestrator emits a nested/tool event for this so the UI can show "booking assistant working…". This is your answer to the doc's "delegate complex tasks" requirement.

### 7.4 AG-UI emitter (AI SDK stream → AG-UI SSE)
There's no first-class AI SDK→AG-UI bridge, so you own ~150 lines. Map `fullStream` parts to AG-UI event types and write them as SSE:

| AI SDK part | AG-UI event(s) |
|---|---|
| run begins | `RUN_STARTED` |
| `text-delta` | `TEXT_MESSAGE_START` / `TEXT_MESSAGE_CONTENT` / `TEXT_MESSAGE_END` |
| `tool-input-start` / `tool-call` | `TOOL_CALL_START` / `TOOL_CALL_ARGS` / `TOOL_CALL_END` |
| `tool-result` | `TOOL_CALL_RESULT` (+ payload the client renders as a rich widget) |
| booking-context change | `STATE_SNAPSHOT` / `STATE_DELTA` (JSON-Patch) |
| `finish` | `RUN_FINISHED` |
| `error` | `RUN_ERROR` |

Endpoint: `POST /agent/run` → sets `Content-Type: text/event-stream`, streams AG-UI events. Include `threadId`/`runId` so the Dart client tracks the session.

**Done when:** `curl -N` on `/agent/run` streams AG-UI-shaped SSE for a booking conversation that chains ≥20 actions across turns without losing context.

---

## 8. Phase 4 — Flutter AI UI (user app only)

Wire `ag_ui` (0.3.0) + `flutter_gen_ai_chat_ui` (2.14.0). A **ChatBloc** consumes `AgUiClient.runAgent()` and translates AG-UI events → `ChatMessagesController`:

- `TextMessageContentEvent` → stream into a bubble: push an empty `ChatMessage` with a stable id, then `updateMessage` with the same id per delta (`enableMarkdownStreaming: true`, `streamingWordByWord: true`).
- `ToolCallStartEvent` → show a `ChatMessage.loading()` shimmer ("checking seats…").
- `ToolCallResultEvent` → replace with a **`ChatMessage.rich()`** widget via the result-renderer registry — a seat map, movie card, or booking summary rendered natively.
- `StateSnapshot/Delta` → keep a client-side booking-context store (JSON-Patch apply) so the UI reflects held seats / running total.
- `onCancelGenerating` → cancel the `AgUiClient` `CancelToken` **and** finalize the partial bubble. (Heads-up: OpenRouter mid-stream cancel is provider-dependent — Anthropic/OpenAI stop billing on abort, some providers keep generating.)

> Use `flutter_gen_ai_chat_ui`'s streaming + rich-widget features, **not** its `AiActionProvider` — that assumes *client-side* tool execution, but your tools run server-side. The one piece worth borrowing is its human-in-the-loop confirmation dialog for the final book/pay step.

**Done when:** the doc's weekend-sci-fi scenario plays out conversationally — search → details → reviews → theatres → seats → hold → promo → pay → confirm — with tool results rendered as widgets, not walls of text.

---

## 9. Phase 5 — Admin (React + Vite)

Thin CRUD over Admin APIs (reuses Phase-1 services): user management (view/edit/disable, assign roles), movie catalog, theatre/screen config, reports (daily/weekly/monthly booking + revenue — compute server-side, render with a light chart lib), activity log viewer, override scheduling. No design ambition; correctness + the activity log for "accountability" is what's graded.

---

## 10. Cross-cutting (Part 3) — wire inline, not last

- **Observability:** every agent tool call logs `{ correlationId, tool, args-summary, durationMs, ok }`. Expose a `/metrics`-ish summary (error rate by type, avg conversation length, tool latency). The correlation ID makes a single interaction traceable end-to-end.
- **Retries:** exponential backoff on transient failures (model/network/db) — cap attempts, jitter.
- **Circuit breaker (payments):** wrap the payment service. After N consecutive failures → OPEN for a cooldown → return a helpful message instead of hammering. HALF-OPEN probe to recover. Keep breaker state in Redis so it's shared across instances.
- **Rate limits (Redis sliding window):** chat 30/min/user, booking 5/hr/user, phone-verify 5/hr/phone. On limit → `429` + `retryAfter`.

---

## 11. Reserved stretch — A2UI (~3–4h, only if everything else lands)

A2UI is Google's declarative generative-UI protocol (stable v0.9.1, transport-agnostic, rides on AG-UI). Flutter's GenUI SDK renders it — **both are alpha/experimental and expected to churn**, so keep this contained and non-load-bearing.

Scope for the time box: **one** agent-generated input form — e.g. a "booking preferences" widget (date picker + time-of-day + party size + seat category) that the agent composes from a **client-defined catalog** of trusted Flutter widgets and sends as an A2UI JSON payload over your existing AG-UI stream. On submit, fire a named event back to the agent. Do **not** let the agent emit arbitrary UI — the catalog is the security boundary. If it fights you, cut it without regret; the rich-widget approach in §8 already covers the core UX.

---

## 12. Demo checklist (mapped to the rubric)

- [ ] RBAC: each role sees only what it should; sessions persist; refresh works.
- [ ] Booking: seat map with real-time (polled) availability, 5-min hold, colour-coded categories, simulated pay (all 3 card behaviours), refund, booking ID.
- [ ] Concurrency: two clients race one seat → exactly one booking.
- [ ] Hall rules: overlap / 30-min gap / 30-day / booked-show-lock each rejected with a specific message.
- [ ] **Agent: 26 tools, sub-agent delegation, ≥20-action conversation with retained context, action-chaining** — the headline demo.
- [ ] AG-UI streaming into the Flutter chat with rich tool-result widgets.
- [ ] Admin: catalog + reports + activity log.
- [ ] Part 3: logs with correlation IDs, retries, payment circuit breaker, rate limits all demonstrable.
- [ ] Docs: README with the two-path architecture diagram + the "why custom loop, not a framework" note (they're explicitly grading this).

---

### The one framing line for your README
> The chatbot is a hand-written orchestration loop over the AI SDK's low-level `streamText` primitive — tool registry, sub-agent delegation, action-chaining, and context compaction are all custom — with a thin AG-UI adapter translating model stream events into a standard client protocol. No agent framework is used.
