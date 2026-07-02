import { Router } from 'express';
import { getShows, getShowById } from '../services/showService.js';
import { getSeatAvailability } from '../services/seatService.js';
import { holdSeats, releaseHold } from '../services/holdService.js';
import { requireAuth } from '../middlewares/authMiddleware.js';
import {
  showQuerySchema,
  holdRequestSchema,
  releaseHoldSchema,
} from '../schemas/index.js';

const router = Router();

// GET /shows?movieId=&date=&city=&screenType=&format=
router.get('/', async (req, res, next) => {
  try {
    const input = showQuerySchema.parse(req.query);
    const shows = await getShows(input);
    res.json({ shows });
  } catch (err) {
    next(err);
  }
});

// GET /shows/:id
router.get('/:id', async (req, res, next) => {
  try {
    const show = await getShowById(String(req.params['id']));
    if (!show) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Show not found' } });
      return;
    }
    res.json({ show });
  } catch (err) {
    next(err);
  }
});

// GET /shows/:id/seats  — polling endpoint
router.get('/:id/seats', async (req, res, next) => {
  try {
    const seats = await getSeatAvailability(String(req.params['id']));
    if (!seats) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Show not found' } });
      return;
    }
    res.json({ seats });
  } catch (err) {
    next(err);
  }
});

// POST /shows/:id/holds
router.post('/:id/holds', requireAuth, async (req, res, next) => {
  try {
    const { seatIds } = holdRequestSchema.parse(req.body);
    const result = await holdSeats(String(req.params['id']), seatIds, req.user!.id);
    if ('failedSeatIds' in result) {
      res.status(409).json({
        error: {
          code: 'SEATS_UNAVAILABLE',
          message: 'One or more seats are already held or booked',
          details: { failedSeatIds: result.failedSeatIds },
        },
      });
      return;
    }
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

// DELETE /shows/:id/holds
router.delete('/:id/holds', requireAuth, async (req, res, next) => {
  try {
    const { holdToken } = releaseHoldSchema.parse(req.body);
    // We need the seatIds to release — client must supply them
    // Accept seatIds from body for release
    const body = req.body as { holdToken: string; seatIds?: string[] };
    const seatIds: string[] = body.seatIds ?? [];
    await releaseHold(String(req.params['id']), seatIds, req.user!.id, holdToken);
    res.json({ released: true });
  } catch (err) {
    next(err);
  }
});

export default router;
