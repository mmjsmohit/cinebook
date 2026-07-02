import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';
import { redisClient } from '../redis.js';
import { JWT_SECRET } from '../config.js';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { phoneVerifyRateLimiter } from '../infra/rateLimiter.js';

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

router.post('/request-otp', phoneVerifyRateLimiter, async (req, res) => {
  const { phone } = requestOtpSchema.parse(req.body);

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
