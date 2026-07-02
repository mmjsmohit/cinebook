diff --git a/cinebook-server/package.json b/cinebook-server/package.json
index 49483d3..7e2474e 100644
--- a/cinebook-server/package.json
+++ b/cinebook-server/package.json
@@ -11,26 +11,32 @@
   "license": "ISC",
   "type": "module",
   "engines": {
     "node": ">=22"
   },
   "dependencies": {
     "@prisma/client": "^5.22.0",
     "cors": "^2.8.6",
     "dotenv": "^17.4.2",
     "express": "^5.2.1",
+    "jsonwebtoken": "^9.0.3",
     "redis": "^6.1.0",
+    "uuid": "^14.0.1",
     "zod": "^4.4.3"
   },
   "prisma": {
     "seed": "tsx prisma/seed.ts"
   },
   "devDependencies": {
     "@types/cors": "^2.8.19",
     "@types/express": "^5.0.6",
+    "@types/jsonwebtoken": "^9.0.10",
     "@types/node": "^26.1.0",
+    "@types/supertest": "^7.2.0",
+    "@types/uuid": "^10.0.0",
     "prisma": "^5.22.0",
+    "supertest": "^7.2.2",
     "ts-node": "^10.9.2",
     "tsx": "^4.22.4",
     "typescript": "^6.0.3"
   }
 }
diff --git a/cinebook-server/src/db.ts b/cinebook-server/src/db.ts
new file mode 100644
index 0000000..9b6c4ce
--- /dev/null
+++ b/cinebook-server/src/db.ts
@@ -0,0 +1,3 @@
+import { PrismaClient } from '@prisma/client';
+
+export const prisma = new PrismaClient();
diff --git a/cinebook-server/src/middlewares/authMiddleware.ts b/cinebook-server/src/middlewares/authMiddleware.ts
new file mode 100644
index 0000000..3496ec6
--- /dev/null
+++ b/cinebook-server/src/middlewares/authMiddleware.ts
@@ -0,0 +1,51 @@
+import type { Request, Response, NextFunction } from 'express';
+import jwt from 'jsonwebtoken';
+
+const JWT_SECRET = process.env.JWT_SECRET || 'secret';
+
+export const requireAuth = (req: Request, res: Response, next: NextFunction) => {
+  const authHeader = req.headers.authorization;
+  if (!authHeader || !authHeader.startsWith('Bearer ')) {
+    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Missing or invalid token' } });
+    return;
+  }
+
+  const token = authHeader.split(' ')[1];
+
+  try {
+    const payload = jwt.verify(token, JWT_SECRET) as { sub: string; role: string; jti: string };
+    req.user = { id: payload.sub, role: payload.role };
+    next();
+  } catch (error) {
+    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Token expired or invalid' } });
+    return;
+  }
+};
+
+export const requireRole = (...roles: string[]) => {
+  return (req: Request, res: Response, next: NextFunction) => {
+    if (!req.user) {
+      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Not authenticated' } });
+      return;
+    }
+
+    if (!roles.includes(req.user.role)) {
+      res.status(403).json({ error: { code: 'FORBIDDEN', message: `Role ${req.user.role} is not authorized` } });
+      return;
+    }
+
+    next();
+  };
+};
+
+// Add to express request type globally
+declare global {
+  namespace Express {
+    interface Request {
+      user?: {
+        id: string;
+        role: string;
+      };
+    }
+  }
+}
diff --git a/cinebook-server/src/middlewares/errorMiddleware.ts b/cinebook-server/src/middlewares/errorMiddleware.ts
new file mode 100644
index 0000000..6eebdd8
--- /dev/null
+++ b/cinebook-server/src/middlewares/errorMiddleware.ts
@@ -0,0 +1,23 @@
+import type { Request, Response, NextFunction } from 'express';
+import { ZodError } from 'zod';
+
+export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
+  if (err instanceof ZodError) {
+    res.status(400).json({
+      error: {
+        code: 'VALIDATION_ERROR',
+        message: 'Invalid request data',
+        details: err.errors
+      }
+    });
+    return;
+  }
+
+  console.error(err);
+  res.status(500).json({
+    error: {
+      code: 'INTERNAL_SERVER_ERROR',
+      message: 'An unexpected error occurred'
+    }
+  });
+};
diff --git a/cinebook-server/src/redis.ts b/cinebook-server/src/redis.ts
new file mode 100644
index 0000000..9c0b2e5
--- /dev/null
+++ b/cinebook-server/src/redis.ts
@@ -0,0 +1,15 @@
+import { createClient } from 'redis';
+import dotenv from 'dotenv';
+dotenv.config();
+
+export const redisClient = createClient({
+  url: process.env.REDIS_URL || 'redis://127.0.0.1:6379'
+});
+
+redisClient.on('error', (err) => console.log('Redis Client Error', err));
+
+export const connectRedis = async () => {
+  if (!redisClient.isOpen) {
+    await redisClient.connect();
+  }
+};
diff --git a/cinebook-server/src/routes/auth.ts b/cinebook-server/src/routes/auth.ts
new file mode 100644
index 0000000..fb31836
--- /dev/null
+++ b/cinebook-server/src/routes/auth.ts
@@ -0,0 +1,124 @@
+import { Router } from 'express';
+import { z } from 'zod';
+import { prisma } from '../db.js';
+import { redisClient } from '../redis.js';
+import jwt from 'jsonwebtoken';
+import { v4 as uuidv4 } from 'uuid';
+
+const router = Router();
+const JWT_SECRET = process.env.JWT_SECRET || 'secret';
+
+const requestOtpSchema = z.object({
+  phone: z.string().min(10).max(15)
+});
+
+const verifyOtpSchema = z.object({
+  phone: z.string().min(10).max(15),
+  code: z.string().length(6)
+});
+
+const refreshSchema = z.object({
+  refreshToken: z.string()
+});
+
+const checkRateLimit = async (phone: string) => {
+  const windowMs = 3600 * 1000; // 1 hour
+  const limit = 5;
+  const now = Date.now();
+  const key = `ratelimit:otp:${phone}`;
+  
+  await redisClient.zRemRangeByScore(key, 0, now - windowMs);
+  
+  const count = await redisClient.zCard(key);
+  if (count >= limit) {
+    const oldest = await redisClient.zRange(key, 0, 0);
+    const retryAfter = oldest && oldest.length > 0 ? (parseInt(oldest[0]) + windowMs - now) / 1000 : windowMs / 1000;
+    return { limited: true, retryAfter: Math.ceil(retryAfter) };
+  }
+  
+  await redisClient.zAdd(key, [{ score: now, value: now.toString() }]);
+  await redisClient.expire(key, 3600);
+  
+  return { limited: false, retryAfter: 0 };
+};
+
+router.post('/request-otp', async (req, res, next) => {
+  try {
+    const { phone } = requestOtpSchema.parse(req.body);
+    
+    const { limited, retryAfter } = await checkRateLimit(phone);
+    if (limited) {
+      res.status(429).json({
+        error: { code: 'TOO_MANY_REQUESTS', message: 'Rate limit exceeded', details: { retryAfter } }
+      });
+      return;
+    }
+
+    const code = Math.floor(100000 + Math.random() * 900000).toString();
+    console.log(`[SIMULATED OTP] phone=${phone} code=${code}`);
+    await redisClient.setEx(`otp:${phone}`, 300, code);
+
+    res.status(202).json({ message: 'OTP requested' });
+  } catch (error) {
+    next(error);
+  }
+});
+
+router.post('/verify-otp', async (req, res, next) => {
+  try {
+    const { phone, code } = verifyOtpSchema.parse(req.body);
+    
+    const storedCode = await redisClient.get(`otp:${phone}`);
+    if (!storedCode || storedCode !== code) {
+      res.status(400).json({ error: { code: 'INVALID_OTP', message: 'Invalid or expired OTP' } });
+      return;
+    }
+    
+    await redisClient.del(`otp:${phone}`);
+
+    let user = await prisma.user.findUnique({ where: { phone } });
+    if (!user) {
+      user = await prisma.user.create({ data: { phone } });
+    }
+
+    const jti = uuidv4();
+    const accessToken = jwt.sign({ sub: user.id, role: user.role, jti }, JWT_SECRET, { expiresIn: '15m' });
+    const refreshToken = jwt.sign({ sub: user.id, role: user.role, jti }, JWT_SECRET, { expiresIn: '7d' });
+    
+    await redisClient.setEx(`refresh_token:${user.id}:${jti}`, 7 * 24 * 3600, 'valid');
+
+    res.json({ accessToken, refreshToken, user });
+  } catch (error) {
+    next(error);
+  }
+});
+
+router.post('/refresh', async (req, res, next) => {
+  try {
+    const { refreshToken } = refreshSchema.parse(req.body);
+    
+    let payload: any;
+    try {
+      payload = jwt.verify(refreshToken, JWT_SECRET);
+    } catch (e) {
+      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid refresh token' } });
+      return;
+    }
+
+    const { sub, jti, role } = payload;
+    
+    const isValid = await redisClient.get(`refresh_token:${sub}:${jti}`);
+    if (!isValid) {
+      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Token revoked or expired' } });
+      return;
+    }
+
+    const accessToken = jwt.sign({ sub, role, jti }, JWT_SECRET, { expiresIn: '15m' });
+
+    res.json({ accessToken });
+  } catch (error) {
+    next(error);
+  }
+});
+
+export default router;
diff --git a/cinebook-server/src/server.ts b/cinebook-server/src/server.ts
new file mode 100644
index 0000000..327af91
--- /dev/null
+++ b/cinebook-server/src/server.ts
@@ -0,0 +1,30 @@
+import express from 'express';
+import cors from 'cors';
+import authRoutes from './routes/auth.js';
+import { connectRedis } from './redis.js';
+import { errorHandler } from './middlewares/errorMiddleware.js';
+
+const app = express();
+
+app.use(cors());
+app.use(express.json());
+
+app.use('/auth', authRoutes);
+
+app.use(errorHandler);
+
+const PORT = process.env.PORT || 3000;
+
+export const startServer = async () => {
+  await connectRedis();
+  app.listen(PORT, () => {
+    console.log(`Server listening on port ${PORT}`);
+  });
+};
+
+// @ts-ignore
+if (import.meta.url === `file://${process.argv[1]}`) {
+  startServer();
+}
+
+export default app;
diff --git a/cinebook-server/test-auth.ts b/cinebook-server/test-auth.ts
new file mode 100644
index 0000000..1d57ade
--- /dev/null
+++ b/cinebook-server/test-auth.ts
@@ -0,0 +1,19 @@
+import { prisma } from './src/db.js';
+import { redisClient, connectRedis } from './src/redis.js';
+import app from './src/server.js';
+import request from 'supertest';
+
+async function main() {
+  await connectRedis();
+  const phone = '8888888888';
+
+  console.log('Testing /auth/request-otp Rate Limit...');
+  for (let i = 1; i <= 6; i++) {
+    const res = await request(app).post('/auth/request-otp').send({ phone });
+    console.log(`Request ${i} Response:`, res.status, res.body);
+  }
+
+  process.exit(0);
+}
+
+main().catch(console.error);
