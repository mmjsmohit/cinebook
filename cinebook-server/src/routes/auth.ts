import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';
import { redisClient } from '../redis.js';
import { JWT_SECRET } from '../config.js';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

const requestOtpSchema = z.object({
  phone: z.string().min(10).max(15)
});

const verifyOtpSchema = z.object({
  phone: z.string().min(10).max(15),
  code: z.string().length(6)
});

const refreshSchema = z.object({
  refreshToken: z.string()
});

/**
 * Atomically implements a sliding-window rate limiter via a Redis Lua script.
 *
 * The Lua script runs entirely inside Redis, so all operations are atomic:
 *   1. ZREMRANGEBYSCORE  – prune entries outside the current window
 *   2. ZCARD             – count remaining entries (read-only check)
 *   3. ZADD (conditional) – only adds the new entry when count < limit
 *   4. ZRANGE            – fetch the oldest entry for retry-after calculation
 *   5. EXPIRE            – refresh the key TTL
 *
 * Returns: [allowed (0|1), retryAfterMs (number)]
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

const checkRateLimit = async (phone: string) => {
  const windowMs = 3600 * 1000; // 1 hour
  const limit = 5;
  const now = Date.now();
  const key = `ratelimit:otp:${phone}`;
  const value = `${now}-${uuidv4()}`;

  const result = await (redisClient as any).eval(
    RATE_LIMIT_SCRIPT,
    {
      keys: [key],
      arguments: [String(now), String(windowMs), String(limit), value, String(3600)]
    }
  ) as [number, number];

  const [allowed, retryAfterMs] = result;
  if (!allowed) {
    return { limited: true, retryAfter: Math.ceil(retryAfterMs / 1000) };
  }
  return { limited: false, retryAfter: 0 };
};

router.post('/request-otp', async (req, res) => {
  const { phone } = requestOtpSchema.parse(req.body);

  const { limited, retryAfter } = await checkRateLimit(phone);
  if (limited) {
    res.status(429).json({
      error: { code: 'TOO_MANY_REQUESTS', message: 'Rate limit exceeded', details: { retryAfter } }
    });
    return;
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  console.log(`[SIMULATED OTP] phone=${phone} code=${code}`);
  await redisClient.setEx(`otp:${phone}`, 300, code);

  res.status(202).json({ message: 'OTP requested' });
});

router.post('/verify-otp', async (req, res) => {
  const { phone, code } = verifyOtpSchema.parse(req.body);

  const results = await redisClient.multi()
    .get(`otp:${phone}`)
    .del(`otp:${phone}`)
    .exec();

  const storedCode = (results[0] as unknown) as string | null;
  if (!storedCode || storedCode !== code) {
    res.status(400).json({ error: { code: 'INVALID_OTP', message: 'Invalid or expired OTP' } });
    return;
  }

  const user = await prisma.user.upsert({
    where: { phone },
    update: {},
    create: { phone }
  });

  const accessJti = uuidv4();
  const refreshJti = uuidv4();
  const accessToken = jwt.sign({ sub: user.id, role: user.role, jti: accessJti, type: 'access' }, JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ sub: user.id, role: user.role, jti: refreshJti, type: 'refresh' }, JWT_SECRET, { expiresIn: '7d' });

  await redisClient.setEx(`refresh_token:${user.id}:${refreshJti}`, 7 * 24 * 3600, 'valid');

  res.json({ accessToken, refreshToken, user });
});

router.post('/refresh', async (req, res) => {
  const { refreshToken } = refreshSchema.parse(req.body);

  let payload: any;
  try {
    payload = jwt.verify(refreshToken, JWT_SECRET);
  } catch (e) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid refresh token' } });
    return;
  }

  const { sub, jti, role, type } = payload;

  if (type !== 'refresh') {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid token type' } });
    return;
  }

  const redisKey = `refresh_token:${sub}:${jti}`;
  const isValid = await redisClient.get(redisKey);
  if (!isValid) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Token revoked or expired' } });
    return;
  }

  // Refresh-token rotation: invalidate old token, issue new pair
  await redisClient.del(redisKey);

  const newAccessJti = uuidv4();
  const newRefreshJti = uuidv4();
  const accessToken = jwt.sign({ sub, role, jti: newAccessJti, type: 'access' }, JWT_SECRET, { expiresIn: '15m' });
  const newRefreshToken = jwt.sign({ sub, role, jti: newRefreshJti, type: 'refresh' }, JWT_SECRET, { expiresIn: '7d' });

  await redisClient.setEx(`refresh_token:${sub}:${newRefreshJti}`, 7 * 24 * 3600, 'valid');

  res.json({ accessToken, refreshToken: newRefreshToken });
});

export default router;
