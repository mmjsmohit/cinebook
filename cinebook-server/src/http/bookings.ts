import { Router } from 'express';
import {
  confirmBooking,
  getBookingById,
  cancelBooking,
  getUserBookings,
} from '../services/bookingService.js';
import { requireAuth } from '../middlewares/authMiddleware.js';
import { confirmBookingSchema } from '../schemas/index.js';
import { bookingRateLimiter } from '../infra/rateLimiter.js';

const router = Router();

// POST /bookings
router.post('/', requireAuth, bookingRateLimiter, async (req, res, next) => {
  try {
    const input = confirmBookingSchema.parse(req.body);
    const result = await confirmBooking(req.user!.id, input);
    res.status(201).json(result);
  } catch (err: unknown) {
    const e = err as any;
    if (e?.code === 'HOLD_LAPSED' || e?.code === 'SEAT_TAKEN') {
      res.status(409).json({ error: { code: e.code, message: e.message, details: e.details } });
      return;
    }
    if (e?.code === 'NOT_FOUND' || e?.code === 'INVALID_SEATS') {
      res.status(404).json({ error: { code: e.code, message: e.message } });
      return;
    }
    next(err);
  }
});

// GET /bookings/:id
router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const booking = await getBookingById(String(req.params['id']), req.user!.id, req.user!.role);
    if (!booking) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Booking not found' } });
      return;
    }
    res.json({ booking });
  } catch (err) {
    next(err);
  }
});

// POST /bookings/:id/cancel
router.post('/:id/cancel', requireAuth, async (req, res, next) => {
  try {
    const result = await cancelBooking(String(req.params['id']), req.user!.id, req.user!.role);
    res.json(result);
  } catch (err: unknown) {
    const e = err as any;
    if (e?.code === 'NOT_FOUND') {
      res.status(404).json({ error: { code: e.code, message: e.message } });
      return;
    }
    if (e?.code === 'FORBIDDEN') {
      res.status(403).json({ error: { code: e.code, message: e.message } });
      return;
    }
    if (e?.code === 'ALREADY_CANCELLED') {
      res.status(409).json({ error: { code: e.code, message: e.message } });
      return;
    }
    next(err);
  }
});

// GET /me/bookings
export const myBookingsRouter = Router();
myBookingsRouter.get('/', requireAuth, async (req, res, next) => {
  try {
    const bookings = await getUserBookings(req.user!.id);
    res.json({ bookings });
  } catch (err) {
    next(err);
  }
});

export default router;
