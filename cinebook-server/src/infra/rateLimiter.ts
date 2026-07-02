import type { Request, Response, NextFunction } from 'express';
import { redisClient } from '../redis.js';
import { v4 as uuidv4 } from 'uuid';

/**
 * Sliding-window rate limiter using the same Lua script approach from auth.ts,
 * extracted into a reusable factory.
 */
const RATE_LIMIT_SCRIPT = `
local key        = KEYS[1]
local now        = tonumber(ARGV[1])
local windowMs   = tonumber(ARGV[2])
local limit      = tonumber(ARGV[3])
local value      = ARGV[4]
local windowSecs = tonumber(ARGV[5])

redis.call('ZREMRANGEBYSCORE', key, 0, now - windowMs)
local count = redis.call('ZCARD', key)

if count >= limit then
  local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
  local oldestScore = oldest[2] and tonumber(oldest[2]) or now
  local retryAfterMs = (oldestScore + windowMs) - now
  return {0, retryAfterMs}
end

redis.call('ZADD', key, now, value)
redis.call('EXPIRE', key, windowSecs)
return {1, 0}
`;

export interface RateLimitOptions {
  limit: number;
  windowSeconds: number;
  keyPrefix: string;
  /** Function to derive the rate-limit key identifier from the request (default: req.user?.id) */
  keyFn?: (req: Request) => string | undefined;
}

export function createRateLimiter(opts: RateLimitOptions) {
  const windowMs = opts.windowSeconds * 1000;

  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const identifier = opts.keyFn
      ? opts.keyFn(req)
      : req.user?.id;

    if (!identifier) {
      next();
      return;
    }

    const key = `${opts.keyPrefix}:${identifier}`;
    const now = Date.now();
    const value = `${now}-${uuidv4()}`;

    const result = await (redisClient as unknown as {
      eval: (script: string, opts: { keys: string[]; arguments: string[] }) => Promise<[number, number]>;
    }).eval(RATE_LIMIT_SCRIPT, {
      keys: [key],
      arguments: [
        String(now),
        String(windowMs),
        String(opts.limit),
        value,
        String(opts.windowSeconds),
      ],
    });

    const [allowed, retryAfterMs] = result;
    if (!allowed) {
      res.status(429).json({
        error: {
          code: 'TOO_MANY_REQUESTS',
          message: 'Rate limit exceeded',
          details: { retryAfter: Math.ceil(retryAfterMs / 1000) },
        },
      });
      return;
    }

    next();
  };
}

/** Pre-built limiters for well-known endpoints */
export const bookingRateLimiter = createRateLimiter({
  limit: 5,
  windowSeconds: 3600,
  keyPrefix: 'ratelimit:booking',
});

export const chatRateLimiter = createRateLimiter({
  limit: 30,
  windowSeconds: 60,
  keyPrefix: 'ratelimit:chat',
});

export const phoneVerifyRateLimiter = createRateLimiter({
  limit: 5,
  windowSeconds: 3600,
  keyPrefix: 'ratelimit:otp',
  keyFn: (req) => req.body.phone,
});
