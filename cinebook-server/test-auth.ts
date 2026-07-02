import assert from 'node:assert/strict';
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

  console.log('=== Testing /auth/request-otp Rate Limit ===');
  for (let i = 1; i <= 6; i++) {
    const res = await request(app).post('/auth/request-otp').send({ phone });
    console.log(`Request ${i}: status=${res.status}`);
    if (i <= 5) {
      assert.equal(res.status, 202, `Request ${i} should succeed (202), got ${res.status}`);
    } else {
      assert.equal(res.status, 429, `Request ${i} should be rate-limited (429), got ${res.status}`);
      assert.ok(res.body.error?.details?.retryAfter, 'Should include retryAfter');
    }
  }

  console.log('\n=== Testing /auth/verify-otp with invalid code ===');
  const invalidVerifyRes = await request(app).post('/auth/verify-otp').send({ phone, code: '000000' });
  console.log(`Verify Invalid OTP: status=${invalidVerifyRes.status}`);
  assert.equal(invalidVerifyRes.status, 400, `Expected 400 for invalid OTP, got ${invalidVerifyRes.status}`);
  assert.equal(invalidVerifyRes.body.error?.code, 'INVALID_OTP');

  // Request new OTP for valid test
  await redisClient.del(`ratelimit:otp:${phone}`);
  await request(app).post('/auth/request-otp').send({ phone });
  const newStoredCode = await redisClient.get(`otp:${phone}`);
  assert.ok(newStoredCode, 'OTP should be stored in Redis');

  console.log(`\n=== Testing /auth/verify-otp with valid code: ${newStoredCode} ===`);
  const verifyRes = await request(app).post('/auth/verify-otp').send({ phone, code: newStoredCode });
  console.log(`Verify OTP: status=${verifyRes.status}`);
  assert.equal(verifyRes.status, 200, `Expected 200 for valid OTP, got ${verifyRes.status}`);
  assert.ok(verifyRes.body.accessToken, 'Should return accessToken');
  assert.ok(verifyRes.body.refreshToken, 'Should return refreshToken');

  const { accessToken, refreshToken } = verifyRes.body;

  console.log('\n=== Testing Protected Route with valid access token ===');
  const protectedRes = await request(app)
    .get('/test-protected')
    .set('Authorization', `Bearer ${accessToken}`);
  console.log(`Protected Route: status=${protectedRes.status}`);
  assert.equal(protectedRes.status, 200, `Expected 200 for valid access token, got ${protectedRes.status}`);

  console.log('\n=== Testing Admin Route with non-admin token (should be forbidden) ===');
  const adminRes = await request(app)
    .get('/test-admin')
    .set('Authorization', `Bearer ${accessToken}`);
  console.log(`Admin Route: status=${adminRes.status}`);
  assert.equal(adminRes.status, 403, `Expected 403 for non-admin user, got ${adminRes.status}`);

  console.log('\n=== Testing Protected Route with refresh token (should fail) ===');
  const protectedRefreshRes = await request(app)
    .get('/test-protected')
    .set('Authorization', `Bearer ${refreshToken}`);
  console.log(`Protected Route (Refresh Token): status=${protectedRefreshRes.status}`);
  assert.equal(protectedRefreshRes.status, 401, `Expected 401 when using refresh token as access token, got ${protectedRefreshRes.status}`);

  console.log('\n=== Testing /auth/refresh with valid refresh token ===');
  const refreshRes = await request(app).post('/auth/refresh').send({ refreshToken });
  console.log(`Refresh Token: status=${refreshRes.status}`);
  assert.equal(refreshRes.status, 200, `Expected 200 for valid refresh, got ${refreshRes.status}`);
  assert.ok(refreshRes.body.accessToken, 'Should return new accessToken');
  assert.ok(refreshRes.body.refreshToken, 'Should return new refreshToken (rotation)');
  assert.notEqual(refreshRes.body.refreshToken, refreshToken, 'New refresh token must differ from old one (rotation)');

  console.log('\n=== Testing refresh-token rotation: old token must be rejected ===');
  const reusedRefreshRes = await request(app).post('/auth/refresh').send({ refreshToken });
  console.log(`Reused old refresh token: status=${reusedRefreshRes.status}`);
  assert.equal(reusedRefreshRes.status, 401, `Old refresh token should be rejected after rotation (401), got ${reusedRefreshRes.status}`);

  console.log('\n=== Testing /auth/refresh with invalid token ===');
  const invalidRefreshRes = await request(app).post('/auth/refresh').send({ refreshToken: 'invalid_token' });
  console.log(`Invalid Refresh Token: status=${invalidRefreshRes.status}`);
  assert.equal(invalidRefreshRes.status, 401, `Expected 401 for invalid refresh token, got ${invalidRefreshRes.status}`);

  console.log('\n✅ All assertions passed!');
  process.exit(0);
}

main().catch((err) => {
  console.error('\n❌ Test failed:', err.message);
  process.exit(1);
});
