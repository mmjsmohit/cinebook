# Task 3: Domain Services & Foundational Infra

## Requirements

### Domain Services (framework-free)

Create pure-logic service files in `src/services/`. These services contain the real business logic. Controllers stay thin (they call services). AI agent tools (Phase 3) will call the same service functions directly.

Services to create:
- `movieService` — search, get by ID, similar, trending, upcoming, reviews
- `showService` — get shows (with filters), get show detail with seat map (merged from BookedSeat + Redis holds + price computation)
- `theatreService` — list theatres (with movieId + city filter)
- `screenService` — get screen detail
- `seatService` — seat availability helper (used by showService)
- `holdService` — Redis hold/release logic (see below)
- `bookingService` — confirm booking (Postgres transaction, see below)
- `paymentService` — simulated payment (see below)
- `promoService` — apply promo code
- `activityLogService` — write admin activity log entries

### Structured Logging + Correlation ID (Part 3 observability — build now)

- Use `AsyncLocalStorage` to hold a per-request `correlationId`.
- Create a structured logger (`src/infra/logger.ts`) that automatically includes the `correlationId` in every log line.
- Create middleware (`src/middlewares/correlationMiddleware.ts`) that extracts or generates a `correlationId` per request (from `X-Correlation-ID` header, or generate a UUID) and stores it in the `AsyncLocalStorage` store.
- Every log line in every service call must carry this ID.

### Rate Limiting Middleware (Redis sliding window)

Create a reusable rate-limit middleware factory at `src/infra/rateLimiter.ts` that accepts `{ limit, windowSeconds, keyPrefix }` and returns Express middleware. This was implemented ad-hoc in Task 2 (auth routes) — extract the Lua-script approach into a shared, reusable utility.

Apply to:
- Chat: 30 per minute per user (placeholder — will be wired in Phase 3)
- Booking: 5 per hour per user
- Phone-verify: 5 per hour per phone (already done inline — wire to this shared util)

### Uniform Error Envelope

Ensure there is a single error envelope shape `{ error: { code, message, details? } }` used everywhere. This was started in Task 2 — verify it is consistently applied.

## REST Endpoints to Implement

### Customer Browse Endpoints (read-only, CUSTOMER+ or public)

```
GET  /movies?releaseDate=&genre=&chain=&screenType=&format=&language=&ageRating=&q=
GET  /movies/:id                 # includes cast, genres, languages
GET  /movies/:id/reviews
GET  /movies/:id/similar         # by shared genre overlap
GET  /movies/trending            # by booking count last 7d
GET  /movies/upcoming?date=
GET  /genres
GET  /languages
GET  /theatres?movieId=&city=    # which theatres show a movie
GET  /screens/:id                # type, format, equipment, capacity
GET  /shows?movieId=&date=&city=&screenType=&format=
GET  /shows/:id
GET  /shows/:id/seats            # POLLING endpoint (see below)
```

Every list endpoint must be Zod-validated on the query params. Define Zod schemas in `src/schemas/` — these same schemas will become agent tool `inputSchema`s in Phase 3.

### Seat Concurrency (The Core)

#### `GET /shows/:id/seats` (polling endpoint)
Returns each seat with state `free | held | booked` and its price. Merge:
- `booked` ← `BookedSeat where showId = :id`
- `held` ← Redis keys `seat:{showId}:*` that exist
- price ← `show.basePrice × categoryMultiplier(seat.category)` (`FRONT` < `STANDARD` < `PREMIUM` < `RECLINER`)

#### Hold — `POST /shows/:id/holds` `{ seatIds[] }`
For each seat: `SET seat:{showId}:{seatId} {ownerToken} NX PX 300000` (5-min TTL). `ownerToken = {userId}:{nonce}`.
- If any `SET` returns null → seat already held/booked → release the ones just grabbed and return `409` with which seats failed.
- On success return `{ holdToken: nonce, expiresAt }`.

#### Release — `DELETE /shows/:id/holds` `{ holdToken }`
Lua compare-and-delete so you never release someone else's hold:
```lua
if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end
```

#### Confirm — `POST /bookings` `{ showId, seatIds[], holdToken, promoCode? }`
Postgres transaction:
1. Re-verify each Redis hold still equals your `ownerToken`. If any expired → `409` (hold lapsed).
2. Insert `Booking (PENDING)` + one `BookedSeat` per seat. The `@@unique([showId, seatId])` constraint is the real race guard — if it throws, someone committed first → roll back, return `409`.
3. Apply promo (promoService), compute `totalCost`, return `{ bookingId, totalCost, status: PENDING }`.
4. Release the holds.

### Booking & Payment Endpoints

```
POST   /bookings                 # confirm (see above)
GET    /bookings/:id             # status
POST   /bookings/:id/cancel      # → CANCELLED, refund if paid, free seats
GET    /me/bookings              # history
POST   /payments                 # { bookingId, cardNumber } → starts processing
POST   /payments/:id/refund
POST   /promo/apply              # { code, amount } → { discounted }
```

Simulated payment (`paymentService`):
- Card behaviours: map test prefixes → always-pass / always-fail / random-fail (~50%).
- Artificial 1–3 s delay.
- Unique `transactionId`; on success → `Booking.status = CONFIRMED`, `Payment.status = SUCCESS`. On failure → keep `PENDING`, surface retryable error.
- `refund()` → `Payment.status = REFUNDED`.
- Wrap the whole payment call in the Circuit Breaker (see below).

### Hall-Manager Scheduling Endpoints

```
GET    /me/screens                       # assigned screens
GET    /screens/:id/shows?from=&to=
POST   /screens/:id/shows                # create
PATCH  /shows/:id
DELETE /shows/:id
```

On create/update, validate and return a **specific error per broken rule** (not a generic 400):
- Manager must own the screen (`managedScreens`); `ADMIN` bypasses.
- No overlap with another show on the same screen.
- ≥ 30 min gap between consecutive shows (cleaning).
- Start ≤ 30 days ahead.
- **Reject edit/delete if any `BookedSeat` exists** for that show.

`endTime = startTime + movie.runtimeMin` (+ optional buffer if desired).

### Circuit Breaker (Payments)

Build a circuit breaker around `paymentService`:
- States: `CLOSED → OPEN` after N consecutive failures → cooldown period → `HALF_OPEN` probe.
- Store counters/state in Redis so it's shared across instances.
- When `OPEN`, return a friendly "payments temporarily unavailable" message instead of hammering.

## Definition of Done

- [ ] All browse endpoints return correct filtered data.
- [ ] Two concurrent holds on one seat → exactly one wins; the other gets a clean `409`.
- [ ] Full booking → payment (all 3 card behaviours) → confirmation with booking ID; refund works.
- [ ] Every hall-scheduling rule rejects with its own specific message; booked shows are locked.
- [ ] Rate limits, payment circuit breaker, and correlation-ID logs all demonstrable.
- [ ] Zod schemas defined in `src/schemas/` (will be reused as agent tool inputSchemas in Phase 3).
