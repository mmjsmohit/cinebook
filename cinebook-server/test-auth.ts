import { prisma } from './src/db.js';
import { redisClient, connectRedis } from './src/redis.js';
import app from './src/server.js';
import request from 'supertest';

async function main() {
  await connectRedis();
  const phone = '8888888888';

  console.log('Testing /auth/request-otp Rate Limit...');
  for (let i = 1; i <= 6; i++) {
    const res = await request(app).post('/auth/request-otp').send({ phone });
    console.log(`Request ${i} Response:`, res.status, res.body);
  }

  process.exit(0);
}

main().catch(console.error);
