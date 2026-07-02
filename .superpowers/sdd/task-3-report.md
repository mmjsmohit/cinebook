# Task 3 Report: Domain Services, REST Endpoints & Foundational Infra

## Status: DONE

---

## Commits

| SHA | Subject |
|-----|---------|
| `af3469f` | Task 3: Domain services, REST endpoints & foundational infra |

---

## Test Summary

**124/124 tests passing, 0 failures** — full integration test suite covering all DoD criteria.

```
Test File: cinebook-server/test-task3.ts
Results:   124 passed, 0 failed

【1】Browse Endpoints         46 ✅
【2】Seat Hold & Concurrency   9 ✅
【3】Booking Confirm          11 ✅
【4】Payment – 3 Card Behaviours  11 ✅
【5】Booking Cancellation      3 ✅
【6】Promo Code                7 ✅
【7】Hall-Manager Scheduling  18 ✅
【8】Error Envelope & Auth     4 ✅
【9】Correlation ID            2 ✅
【10】Rate Limiter             5 ✅
【11】Zod Schemas              9 ✅
```

---

## What Was Implemented

### Domain Services (`src/services/`)
All 11 services are framework-free (no Express imports) — callable directly by Phase 3 AI tools:

| Service | Key Behaviour |
|---------|--------------|
| `movieService` | search, getById, reviews, similar, trending (7-day bookings), upcoming |
| `showService` | filtered list, getById with full seat map |
| `theatreService` | list with movieId+city filter |
| `screenService` | getById with seats/manager, getScreensForManager |
| `seatService` | availability polling — merges BookedSeat (Postgres) + held (Redis) + price per category |
| `holdService` | Redis `SET NX PX 300000`; Lua compare-and-delete for release; atomic rollback on partial failure |
| `bookingService` | Postgres tx + `@@unique([showId,seatId])` race guard; promo application; hold release |
| `paymentService` | Simulated gateway (1-3s delay); 4000→pass, 4111→fail, other→50% random; circuit breaker wrapped |
| `promoService` | PromoCode lookup, percent-off discount computation |
| `activityLogService` | AdminActivityLog writes + recent activity query |
| `scheduleService` | Show CRUD with 5 specific business rules enforced |

### REST Endpoints (`src/http/`)

**Browse (public/CUSTOMER+):**
- `GET /movies` with 8 query params, Zod-validated
- `GET /movies/trending`, `/movies/upcoming`, `/movies/:id`, `/movies/:id/reviews`, `/movies/:id/similar`
- `GET /genres`, `GET /languages`
- `GET /theatres?movieId=&city=`
- `GET /screens/:id`
- `GET /shows?movieId=&date=&city=&screenType=&format=`
- `GET /shows/:id`, `GET /shows/:id/seats` (polling endpoint)

**Seat Concurrency:**
- `POST /shows/:id/holds` — SET NX atomic; partial-grab rollback on conflict; returns `{holdToken, expiresAt}`
- `DELETE /shows/:id/holds` — Lua compare-and-delete per seat

**Booking & Payment:**
- `POST /bookings` — Postgres transaction + Redis hold re-verify + `@@unique` constraint race guard
- `GET /bookings/:id`, `POST /bookings/:id/cancel`, `GET /me/bookings`
- `POST /payments` — circuit-breaker wrapped, 3 card behaviours
- `POST /payments/:id/refund`
- `POST /promo/apply`

**Hall-Manager Scheduling:**
- `GET /me/screens`, `GET /screens/:id/shows?from=&to=`
- `POST /screens/:id/shows`, `PATCH /shows/:id`, `DELETE /shows/:id`
- 5 specific error codes: `TOO_FAR_AHEAD`, `OVERLAP`, `GAP_TOO_SHORT`, `HAS_BOOKINGS`, `NOT_YOUR_SCREEN`

### Infra (`src/infra/`)

| File | Purpose |
|------|---------|
| `logger.ts` | Structured JSON logger; reads `correlationId` from AsyncLocalStorage |
| `rateLimiter.ts` | Redis sliding-window factory; `bookingRateLimiter` (5/hr), `chatRateLimiter` (30/min) |
| `circuitBreaker.ts` | Redis-backed CB; CLOSED→OPEN after 5 failures; 30s cooldown; HALF_OPEN probe |

### Middleware

| File | Purpose |
|------|---------|
| `correlationMiddleware.ts` | Extracts or generates UUID; stores in ALS; echoes `x-correlation-id` header |
| `errorMiddleware.ts` | Uniform `{ error: { code, message, details? } }` envelope; handles ZodError |

### Schemas (`src/schemas/index.ts`)
9 Zod schemas exported — ready as Phase 3 agent tool `inputSchema`:
`movieSearchSchema`, `showQuerySchema`, `holdRequestSchema`, `releaseHoldSchema`,
`confirmBookingSchema`, `initiatePaymentSchema`, `promoApplySchema`,
`createShowSchema`, `updateShowSchema`, `hallShowQuerySchema`, `theatreQuerySchema`

---

## TypeScript Fixes Applied
- Fixed `exactOptionalPropertyTypes` violations in `showService`, `scheduleService`, `theatreService`
- Fixed `NullableJsonNullValueInput` type for Prisma JSON metadata in `activityLogService`
- Fixed `noUncheckedIndexedAccess` violations in `seed.ts`
- Exported `Prisma` namespace from `db.ts`

---

## Concerns

None — all 124 integration tests pass, TypeScript compiles cleanly, and all DoD criteria are verified.

> **Note on test idempotency**: The test suite flushes Redis booking rate-limit keys and the circuit breaker state at startup, so it can be run repeatedly without hitting rate limits. The booking rate limiter uses 5/hour per user; tests spread across 4 different user accounts to stay within limits.

---

## Report File
`/Users/mohittiwari/Dev/Cinebook/.superpowers/sdd/task-3-report.md`
