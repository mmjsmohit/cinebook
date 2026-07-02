import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';
import { redisClient } from '../redis.js';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

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

const checkRateLimit = async (phone: string) => {
  const windowMs = 3600 * 1000; // 1 hour
  const limit = 5;
  const now = Date.now();
  const key = `ratelimit:otp:${phone}`;
  
  await redisClient.zRemRangeByScore(key, 0, now - windowMs);
  
  const count = await redisClient.zCard(key);
  if (count >= limit) {
    const oldest = await redisClient.zRange(key, 0, 0);
    const retryAfter = oldest && oldest.length > 0 ? (parseInt(oldest[0]) + windowMs - now) / 1000 : windowMs / 1000;
    return { limited: true, retryAfter: Math.ceil(retryAfter) };
  }
  
  await redisClient.zAdd(key, [{ score: now, value: now.toString() }]);
  await redisClient.expire(key, 3600);
  
  return { limited: false, retryAfter: 0 };
};

router.post('/request-otp', async (req, res, next) => {
  try {
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
  } catch (error) {
    next(error);
  }
});

router.post('/verify-otp', async (req, res, next) => {
  try {
    const { phone, code } = verifyOtpSchema.parse(req.body);
    
    const storedCode = await redisClient.get(`otp:${phone}`);
    if (!storedCode || storedCode !== code) {
      res.status(400).json({ error: { code: 'INVALID_OTP', message: 'Invalid or expired OTP' } });
      return;
    }
    
    await redisClient.del(`otp:${phone}`);

    let user = await prisma.user.findUnique({ where: { phone } });
    if (!user) {
      user = await prisma.user.create({ data: { phone } });
    }

    const jti = uuidv4();
    const accessToken = jwt.sign({ sub: user.id, role: user.role, jti }, JWT_SECRET, { expiresIn: '15m' });
    const refreshToken = jwt.sign({ sub: user.id, role: user.role, jti }, JWT_SECRET, { expiresIn: '7d' });
    
    await redisClient.setEx(`refresh_token:${user.id}:${jti}`, 7 * 24 * 3600, 'valid');

    res.json({ accessToken, refreshToken, user });
  } catch (error) {
    next(error);
  }
});

router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = refreshSchema.parse(req.body);
    
    let payload: any;
    try {
      payload = jwt.verify(refreshToken, JWT_SECRET);
    } catch (e) {
      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid refresh token' } });
      return;
    }

    const { sub, jti, role } = payload;
    
    const isValid = await redisClient.get(`refresh_token:${sub}:${jti}`);
    if (!isValid) {
      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Token revoked or expired' } });
      return;
    }

    const accessToken = jwt.sign({ sub, role, jti }, JWT_SECRET, { expiresIn: '15m' });

    res.json({ accessToken });
  } catch (error) {
    next(error);
  }
});

export default router;
