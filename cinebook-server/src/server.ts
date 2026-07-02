import express from 'express';
import cors from 'cors';

// Infra & middleware
import { connectRedis } from './redis.js';
import { errorHandler } from './middlewares/errorMiddleware.js';
import { correlationMiddleware } from './middlewares/correlationMiddleware.js';

// Auth routes (Task 2)
import authRoutes from './routes/auth.js';

// HTTP domain routers (Task 3)
import moviesRouter, { genresRouter, languagesRouter } from './http/movies.js';
import theatresRouter from './http/theatres.js';
import screensRouter, { myScreensRouter, showsManageRouter } from './http/screens.js';
import showsRouter from './http/shows.js';
import bookingsRouter, { myBookingsRouter } from './http/bookings.js';
import paymentsRouter from './http/payments.js';
import promoRouter from './http/promo.js';
import agentRouter from './routes/agentRouter.js';
import adminRouter from './http/admin.js';

const app = express();

// ── Global middleware ────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(correlationMiddleware()); // Attaches correlationId to every request

// ── Routes ───────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/auth', authRoutes);

// Browse / public
app.use('/movies', moviesRouter);
app.use('/genres', genresRouter);
app.use('/languages', languagesRouter);
app.use('/theatres', theatresRouter);
app.use('/shows', showsRouter);
app.use('/screens', screensRouter);

// Authenticated
app.use('/bookings', bookingsRouter);
app.use('/payments', paymentsRouter);
app.use('/promo', promoRouter);

// AI Agent (matches standard AG-UI path: /agents/:agentId/run)
app.use('/api/agents', agentRouter);

// /me sub-routes
app.use('/me/bookings', myBookingsRouter);
app.use('/me/screens', myScreensRouter);

// Hall-manager show management (PATCH/DELETE /shows/:id)
app.use('/shows', showsManageRouter);

// Admin dashboard routes
app.use('/admin', adminRouter);

// ── Error handler (must be last) ─────────────────────────────────────────────
app.use(errorHandler);

const PORT = process.env.PORT ?? 3000;

export const startServer = async () => {
  await connectRedis();
  app.listen(PORT, () => {
    console.log(JSON.stringify({ ts: new Date().toISOString(), level: 'info', message: `Server listening on port ${PORT}` }));
  });
};

// @ts-ignore
if (import.meta.url === `file://${process.argv[1]}`) {
  startServer();
}

export default app;
