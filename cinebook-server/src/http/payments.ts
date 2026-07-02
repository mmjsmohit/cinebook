import { Router } from 'express';
import { initiatePayment, refundPayment } from '../services/paymentService.js';
import { requireAuth } from '../middlewares/authMiddleware.js';
import { initiatePaymentSchema } from '../schemas/index.js';

const router = Router();

// POST /payments
router.post('/', requireAuth, async (req, res, next) => {
  try {
    const { bookingId, cardNumber } = initiatePaymentSchema.parse(req.body);
    const result = await initiatePayment(bookingId, cardNumber);
    res.status(201).json(result);
  } catch (err: unknown) {
    const e = err as any;
    if (e?.code === 'CIRCUIT_OPEN') {
      res.status(503).json({ error: { code: 'CIRCUIT_OPEN', message: e.message } });
      return;
    }
    if (e?.code === 'PAYMENT_FAILED') {
      res.status(402).json({
        error: { code: 'PAYMENT_FAILED', message: e.message, details: { retryable: true } },
      });
      return;
    }
    if (e?.code === 'NOT_FOUND') {
      res.status(404).json({ error: { code: e.code, message: e.message } });
      return;
    }
    if (e?.code === 'ALREADY_PAID' || e?.code === 'BOOKING_CANCELLED') {
      res.status(409).json({ error: { code: e.code, message: e.message } });
      return;
    }
    next(err);
  }
});

// POST /payments/:id/refund
router.post('/:id/refund', requireAuth, async (req, res, next) => {
  try {
    const result = await refundPayment(String(req.params['id']), req.user!.id, req.user!.role);
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
    if (e?.code === 'INVALID_STATE') {
      res.status(409).json({ error: { code: e.code, message: e.message } });
      return;
    }
    next(err);
  }
});

export default router;
