import { prisma } from './src/db.js';
import { redisClient, connectRedis } from './src/redis.js';
import app from './src/server.js';
import request from 'supertest';

async function main() {
  await connectRedis();
  const phone = '8888888888';

  // Ensure fresh state by deleting if it exists
  try {
    await redisClient.del(`ratelimit:otp:${phone}`);
  } catch (e) {}

  console.log('Testing /auth/request-otp Rate Limit...');
  for (let i = 1; i <= 6; i++) {
    const res = await request(app).post('/auth/request-otp').send({ phone });
    console.log(`Request ${i} Response:`, res.status, res.body);
  }

  const storedCode = await redisClient.get(`otp:${phone}`);
  console.log(`\nTesting /auth/verify-otp with code: ${storedCode} ...`);
  
  const verifyRes = await request(app).post('/auth/verify-otp').send({ phone, code: storedCode || '123456' });
  console.log(`Verify OTP Response:`, verifyRes.status, verifyRes.body);

  const { accessToken, refreshToken } = verifyRes.body;
  if (refreshToken) {
    console.log('\nTesting /auth/refresh ...');
    const refreshRes = await request(app).post('/auth/refresh').send({ refreshToken });
    console.log(`Refresh Token Response:`, refreshRes.status, refreshRes.body);
  }

  process.exit(0);
}

main().catch(console.error);
