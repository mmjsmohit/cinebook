# Task 2 Report: Auth & RBAC

## What was implemented
- **`/auth/request-otp`**: Simulated OTP generation storing a 6-digit code in Redis (5 min TTL) and responding with 202. Implemented a sliding window rate limit using Redis (`zRemRangeByScore`, `zCard`, `zAdd`, `zRange`) restricting usage to 5 requests per hour per phone number. Rate-limit violations return a 429 status with a `retryAfter` delay.
- **`/auth/verify-otp`**: Verifies phone number against the stored OTP code in Redis. If successful, creates or fetches the `User` via Prisma, generates JWTs (`accessToken` valid for 15 mins, `refreshToken` valid for 7 days), and stores the refresh token's `jti` claim allowlist in Redis with a 7-day TTL.
- **`/auth/refresh`**: Accepts a refresh token, verifies it, checks if its `jti` is allowlisted in Redis, and issues a new access token (15 mins) returning it in the same payload.
- **Middlewares**: Added `requireAuth` to verify the JWT and attach `req.user` (`id`, `role`), and `requireRole(...roles)` to gatekeep based on the user's role returning standard error envelopes.
- **Global Error Handler**: Set up a uniform error envelope `{ error: { code, message, details? } }` parsing `ZodError` exceptions properly.
- All dependencies (`jsonwebtoken`, `uuid`, `express`, `zod`, `redis`) and their typings are correctly integrated.

## What was tested
- I wrote an integration test script (`test-auth.ts`) utilizing `supertest` hitting the live endpoints against local Postgres and Redis environments.
- Verified `/auth/request-otp` logs the OTP and properly rate-limits after 5 requests, rejecting the 6th with 429.
- Verified `/auth/verify-otp` works with the simulated OTP and returns a valid `accessToken`, `refreshToken`, and the `user` object.
- Verified `/auth/refresh` works correctly accepting the newly generated `refreshToken` and outputting a new `accessToken`.

## Files changed
- `cinebook-server/package.json` & `package-lock.json`
- `cinebook-server/src/db.ts` (new)
- `cinebook-server/src/redis.ts` (new)
- `cinebook-server/src/middlewares/authMiddleware.ts` (new)
- `cinebook-server/src/middlewares/errorMiddleware.ts` (new)
- `cinebook-server/src/routes/auth.ts` (new)
- `cinebook-server/src/server.ts` (new)
- `cinebook-server/test-auth.ts` (new)

## Self-review findings
- Code adheres cleanly to all requirements provided.
- Avoided over-engineering. Rate limit algorithm uses standard Redis sorted sets (`ZADD`, `ZREMRANGEBYSCORE`, `ZCARD`) exactly as instructed via `redis` NPM package.
- Commits are scoped.

## Any issues or concerns
- None. Fully ready for the next task.

## Fixes Implemented
- **Critical**: Added `type: 'access' | 'refresh'` claim to the JWT payload. Enforced `if (payload.type !== 'refresh')` in the refresh endpoint, and issued distinct `jti` identifiers for access and refresh tokens. Updated `test-auth.ts` to fully validate the OTP verification and token refresh flows.
- **Important**: Appended a UUID to the `value` in `checkRateLimit`'s Redis `zAdd` to guarantee set member uniqueness. Grouped the rate limit Redis commands into a single `.multi()` transaction block. Grouped the OTP fetch and delete commands into a single `.multi()` transaction block to prevent separated checking and deleting.
- **Minor**: Replaced the `findUnique` and `create` combination with a single `prisma.user.upsert` for atomic user creation. Removed all unnecessary `try/catch` blocks from async Express route handlers.

### Test Output
```
Testing /auth/request-otp Rate Limit...
[SIMULATED OTP] phone=8888888888 code=701903
Request 1 Response: 202 { message: 'OTP requested' }
[SIMULATED OTP] phone=8888888888 code=286527
Request 2 Response: 202 { message: 'OTP requested' }
[SIMULATED OTP] phone=8888888888 code=342844
Request 3 Response: 202 { message: 'OTP requested' }
[SIMULATED OTP] phone=8888888888 code=521942
Request 4 Response: 202 { message: 'OTP requested' }
[SIMULATED OTP] phone=8888888888 code=613811
Request 5 Response: 202 { message: 'OTP requested' }
Request 6 Response: 429 {
  error: {
    code: 'TOO_MANY_REQUESTS',
    message: 'Rate limit exceeded',
    details: { retryAfter: 3600 }
  }
}

Testing /auth/verify-otp with code: 613811 ...
Verify OTP Response: 200 {
  accessToken: '...',
  refreshToken: '...',
  user: {
    id: 'cmr3hyoj9000077zy29in0ehc',
    phone: '8888888888',
    name: null,
    role: 'CUSTOMER',
    disabled: false,
    prefs: null,
    createdAt: '2026-07-02T12:45:03.280Z'
  }
}

Testing /auth/refresh ...
Refresh Token Response: 200 {
  accessToken: '...'
}
```
