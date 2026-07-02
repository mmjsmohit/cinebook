import { prisma } from './src/db.js';
import { redisClient, connectRedis } from './src/redis.js';
import app from './src/server.js';
import request from 'supertest';
import { requireAuth, requireRole } from './src/middlewares/authMiddleware.js';

// Add dummy protected routes for testing
app.get('/test-protected', requireAuth, (req, res) => {
  res.json({ message: 'Success', user: req.user });
});
app.get('/test-admin', requireAuth, requireRole('ADMIN'), (req, res) => {
  res.json({ message: 'Success Admin', user: req.user });
});

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
  console.log('\nTesting /auth/verify-otp with invalid code...');
  const invalidVerifyRes = await request(app).post('/auth/verify-otp').send({ phone, code: '000000' });
  console.log(`Verify Invalid OTP Response:`, invalidVerifyRes.status, invalidVerifyRes.body);

  // Request new OTP for valid test
  await redisClient.del(`ratelimit:otp:${phone}`);
  await request(app).post('/auth/request-otp').send({ phone });
  const newStoredCode = await redisClient.get(`otp:${phone}`);

  console.log(`\nTesting /auth/verify-otp with code: ${newStoredCode} ...`);
  
  const verifyRes = await request(app).post('/auth/verify-otp').send({ phone, code: newStoredCode || '123456' });
  console.log(`Verify OTP Response:`, verifyRes.status, verifyRes.body);

  const { accessToken, refreshToken } = verifyRes.body;
  
  if (accessToken) {
    console.log('\nTesting Protected Route with valid token...');
    const protectedRes = await request(app)
      .get('/test-protected')
      .set('Authorization', `Bearer ${accessToken}`);
    console.log(`Protected Route Response:`, protectedRes.status, protectedRes.body);

    console.log('\nTesting Admin Route with user token...');
    const adminRes = await request(app)
      .get('/test-admin')
      .set('Authorization', `Bearer ${accessToken}`);
    console.log(`Admin Route Response (should fail):`, adminRes.status, adminRes.body);

    console.log('\nTesting Protected Route with refresh token (should fail)...');
    const protectedRefreshRes = await request(app)
      .get('/test-protected')
      .set('Authorization', `Bearer ${refreshToken}`);
    console.log(`Protected Route (Refresh Token) Response:`, protectedRefreshRes.status, protectedRefreshRes.body);
  }

  if (refreshToken) {
    console.log('\nTesting /auth/refresh with valid token...');
    const refreshRes = await request(app).post('/auth/refresh').send({ refreshToken });
    console.log(`Refresh Token Response:`, refreshRes.status, refreshRes.body);

    console.log('\nTesting /auth/refresh with invalid token...');
    const invalidRefreshRes = await request(app).post('/auth/refresh').send({ refreshToken: 'invalid_token' });
    console.log(`Invalid Refresh Token Response:`, invalidRefreshRes.status, invalidRefreshRes.body);
  }

  process.exit(0);
}

main().catch(console.error);
