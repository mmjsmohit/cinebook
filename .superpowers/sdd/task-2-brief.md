# Task 2: Auth & RBAC

## Requirements

Simulated phone OTP; real JWT.

Implement the following endpoints in an Express app (setup `src/server.ts` or similar):

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/auth/request-otp` | `{ phone }` | `202` (logs a fake 6-digit code) — rate-limited 5/hr/phone |
| POST | `/auth/verify-otp` | `{ phone, code }` | `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | `{ refreshToken }` | `{ accessToken }` |

- Access token 15 min, refresh 7 days. Payload carries `sub`, `role`, `jti`.
- Implement `requireAuth` middleware that verifies the JWT and attaches `req.user`.
- Implement `requireRole(...roles)` middleware that gates by `role` claim → returns `403` with a clear body if missing.
- Store refresh-token `jti` allowlist in Redis so logout/rotation is possible.
- Include a sliding-window rate limit (using node-redis) for the `request-otp` route (5 requests per hour per phone number), which returns `429 { retryAfter }` when exceeded.

Use Zod for request body validation. Establish the uniform error envelope `{ error: { code, message, details? } }` for validation and rate-limit errors.
