# Phase 1 — CRUD Backend + Foundation

**Stack:** Node 22+, Express, TypeScript, Prisma + PostgreSQL, node-redis, Zod, JWT.
**Purpose:** Every non-AI backend capability for all three roles, plus the foundational infra (auth, logging, rate limits, circuit breaker) the later phases lean on.

**Tightly tied to:**
- **Feeds Phase 2** (Flutter apps) — every endpoint below is consumed by the user/hall apps.
- **Reused by Phase 3** (AI backend) — the *services* here are wrapped 1:1 as agent tools. Keep them framework-free.
- **Reused by Phase 5** (Admin) — admin screens call the same services through `/admin/*` routes.

This document is the source of truth for the **REST contract**. Phases 2 and 5 must match these names exactly.

---

## 1. Bootstrapping

- `docker-compose.yml`: `postgres:16`, `redis:7`.
- Prisma schema = the one in `CineBook-Build-Plan.md §3` (13 required entities + `Review`, `PromoCode`, `Conversation`, `Message`). `prisma migrate dev` → seed.
- **Seed script** must produce a demoable world: 3 theatre chains × 2–3 screens each, seat layouts per screen (rows A–J, categories mapped by row band), 6–8 movies with genres/cast/reviews, shows across the next 7 days, 2–3 promo codes, and one user per role (`CUSTOMER`, `HALL_MANAGER` with `managedScreens`, `ADMIN`).
- Node **22+** is required (aligns with `ai@7` in Phase 3 — pin it now so both phases share one runtime).

---

## 2. Auth & RBAC

Simulated phone OTP; real JWT.

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/auth/request-otp` | `{ phone }` | `202` (logs a fake 6-digit code) — rate-limited 5/hr/phone |
| POST | `/auth/verify-otp` | `{ phone, code }` | `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | `{ refreshToken }` | `{ accessToken }` |

- Access token 15 min, refresh 7 days. Payload carries `sub`, `role`, `jti`.
- `requireAuth` middleware verifies + attaches `req.user`. `requireRole(...roles)` gates by `role` claim → `403` with a clear body.
- Store refresh-token `jti` allowlist in Redis so logout/rotation is possible.

---

## 3. Domain services (framework-free)

Put pure logic in `src/services/*`. Controllers stay thin. **This is the boundary Phase 3 depends on** — an agent tool's `execute` calls the exact same service function a controller does.

Services: `movieService`, `showService`, `theatreService`, `screenService`, `seatService`, `holdService`, `bookingService`, `paymentService`, `promoService`, `activityLogService`.

---

## 4. REST contract — customer browse

All read-only, `CUSTOMER`+ (or public).

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
GET  /shows/:id/seats            # POLLING endpoint — see §5
```

Every list endpoint is Zod-validated on the query; the same Zod schemas become tool `inputSchema`s in Phase 3, so define them in `src/schemas` and import both places.

---

## 5. Seat concurrency (the core)

Two layers: **Redis holds** (fast, TTL, temporary) + **Postgres unique constraint** (final truth). This is the pattern the reference video demonstrates in Go, translated to node-redis.

### `GET /shows/:id/seats` (polling)
Returns each seat with state `free | held | booked` and its price. Merge:
- `booked` ← `BookedSeat where showId = :id`
- `held` ← Redis keys `seat:{showId}:*` that exist
- price ← `show.basePrice × categoryMultiplier(seat.category)` (`FRONT` < `STANDARD` < `PREMIUM` < `RECLINER`)

Client polls this every ~2–3 s (Phase 2 §5).

### Hold — `POST /shows/:id/holds` `{ seatIds[] }`
For each seat: `SET seat:{showId}:{seatId} {ownerToken} NX PX 300000` (5-min TTL). `ownerToken = {userId}:{nonce}`. If any `SET` returns null → seat already held/booked → **release the ones you just grabbed** and return `409` with which seats failed. On success return `{ holdToken: nonce, expiresAt }`.

### Release — `DELETE /shows/:id/holds` `{ holdToken }`
Lua **compare-and-delete** so you never release someone else's hold:
```lua
if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end
```

### Confirm — `POST /bookings` `{ showId, seatIds[], holdToken, promoCode? }`
Postgres transaction:
1. Re-verify each Redis hold still equals your `ownerToken`. If any expired → `409` (hold lapsed).
2. Insert `Booking (PENDING)` + one `BookedSeat` per seat. The `@@unique([showId, seatId])` constraint is the real race guard — if it throws, someone committed first → roll back, return `409`.
3. (Optional) `SELECT ... FOR UPDATE` on the show row for extra serialization.
4. Apply promo (§7), compute `totalCost`, return `{ bookingId, totalCost, status: PENDING }`.
5. Release the holds (payment will confirm the booking).

> **Why both layers:** Redis gives auto-expiring 5-min holds (Postgres has no row TTL); the unique constraint guarantees correctness even if a hold expires mid-flight.

---

## 6. Booking & payment endpoints

```
POST   /bookings                 # confirm (see §5)
GET    /bookings/:id             # status
POST   /bookings/:id/cancel      # -> CANCELLED, refund if paid, free seats
GET    /me/bookings              # history
POST   /payments                 # { bookingId, cardNumber } -> starts processing
POST   /payments/:id/refund
POST   /promo/apply              # { code, amount } -> { discounted }
```

### Simulated payment (`paymentService`)
- **Card behaviours:** map test prefixes → always-pass / always-fail / random-fail (~50%).
- Artificial **1–3 s delay** (`setTimeout`).
- Unique `transactionId`; on success → `Booking.status = CONFIRMED`, `Payment.status = SUCCESS`. On failure → keep `PENDING`, surface a retryable error.
- `refund()` → `Payment.status = REFUNDED`.
- **Wrap the whole payment call in the circuit breaker (§8).**

---

## 7. Hall-manager scheduling (server-enforced rules)

```
GET    /me/screens                       # assigned screens
GET    /screens/:id/shows?from=&to=
POST   /screens/:id/shows                # create
PATCH  /shows/:id
DELETE /shows/:id
```

On create/update, validate and return a **specific error per broken rule** (not a generic 400):
- Manager must own the screen (`managedScreens`); `ADMIN` bypasses (override).
- No overlap with another show on the same screen.
- ≥ 30 min gap between consecutive shows (cleaning).
- Start ≤ 30 days ahead.
- **Reject edit/delete if any `BookedSeat` exists** for that show.

`endTime = startTime + movie.runtimeMin` (+ optional buffer). Phase 2's hall app renders these exact error messages.

---

## 8. Foundational infra (Part 3 basics — build now, not last)

- **Structured logging + correlation ID:** `AsyncLocalStorage` holds a per-request `correlationId`; every log line and (Phase 3) every tool call carries it. This is what makes a single interaction traceable end-to-end.
- **Rate limiting (Redis sliding window), returns `429 { retryAfter }`:**
  - chat 30/min/user (used in Phase 3), booking 5/hr/user, phone-verify 5/hr/phone.
- **Circuit breaker (payments):** `CLOSED → OPEN` after N consecutive failures → cooldown → `HALF_OPEN` probe. Store counters/state in Redis so it's shared across instances. When `OPEN`, return a friendly "payments temporarily unavailable" instead of hammering.
- **Uniform error envelope:** `{ error: { code, message, details? } }`. Both the REST clients (Phase 2/5) and the agent tools (Phase 3) rely on this shape.

---

## 9. Definition of done

- [ ] All three roles authenticate; tokens refresh; wrong-role routes `403`.
- [ ] Browse + all filters return correct data.
- [ ] Two concurrent holds on one seat → exactly one wins; the other gets a clean `409`.
- [ ] Full booking → payment (all 3 card behaviours) → confirmation with booking ID; refund works.
- [ ] Every hall-scheduling rule rejects with its own specific message; booked shows are locked.
- [ ] Rate limits, payment circuit breaker, and correlation-ID logs all demonstrable.

---

## 10. Reference documentation

- Express — https://expressjs.com/
- Prisma docs (schema, migrate, Client, transactions) — https://www.prisma.io/docs
- Zod — https://zod.dev/
- node-redis client — https://github.com/redis/node-redis
- Redis `SET` (NX / PX for holds) — https://redis.io/docs/latest/commands/set/
- Redis `EVAL` (Lua compare-and-delete) — https://redis.io/docs/latest/commands/eval/
- jsonwebtoken — https://github.com/auth0/node-jsonwebtoken
- Seat-locking pattern (Ticketmaster breakdown) — https://www.hellointerview.com/learn/system-design/problem-breakdowns/ticketmaster
- Double-booking with Redis — https://cgorale111.medium.com/avoiding-double-booking-with-redis-aca66fefcce3
- Go + Redis + Postgres booking service — https://medium.com/@rayancr/building-a-booking-service-backend-like-ticketmaster-and-bookmyshow-using-go-redis-and-postgresql-a4caa1f1105e
- Reference video (concurrent booking) — https://youtu.be/CIIrR5daWL4
