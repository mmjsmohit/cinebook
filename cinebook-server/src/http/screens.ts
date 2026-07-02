import { Router } from 'express';
import { getScreenById, getScreensForManager } from '../services/screenService.js';
import { requireAuth, requireRole } from '../middlewares/authMiddleware.js';
import {
  getShowsForScreen,
  createShow,
  updateShow,
  deleteShow,
} from '../services/scheduleService.js';
import { createShowSchema, updateShowSchema, hallShowQuerySchema } from '../schemas/index.js';

const router = Router();

// GET /screens/:id
router.get('/:id', async (req, res, next) => {
  try {
    const screen = await getScreenById(String(req.params['id']));
    if (!screen) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Screen not found' } });
      return;
    }
    res.json({ screen });
  } catch (err) {
    next(err);
  }
});

// GET /me/screens  (hall-manager: their assigned screens)
export const myScreensRouter = Router();
myScreensRouter.get(
  '/',
  requireAuth,
  requireRole('HALL_MANAGER', 'ADMIN'),
  async (req, res, next) => {
    try {
      const screens = await getScreensForManager(req.user!.id);
      res.json({ screens });
    } catch (err) {
      next(err);
    }
  }
);

// GET /screens/:id/shows?from=&to=
router.get(
  '/:id/shows',
  requireAuth,
  requireRole('HALL_MANAGER', 'ADMIN'),
  async (req, res, next) => {
    try {
      const { from, to } = hallShowQuerySchema.parse(req.query);
      const shows = await getShowsForScreen(String(req.params['id']), from, to);
      res.json({ shows });
    } catch (err) {
      next(err);
    }
  }
);

// POST /screens/:id/shows
router.post(
  '/:id/shows',
  requireAuth,
  requireRole('HALL_MANAGER', 'ADMIN'),
  async (req, res, next) => {
    try {
      const input = createShowSchema.parse(req.body);
      const show = await createShow(
        String(req.params['id']),
        req.user!.id,
        req.user!.role,
        input
      );
      res.status(201).json({ show });
    } catch (err: unknown) {
      if ((err as any)?.scheduling) {
        res.status(422).json({
          error: { code: (err as any).code, message: (err as Error).message },
        });
        return;
      }
      next(err);
    }
  }
);

export default router;

// Shows router for PATCH /shows/:id and DELETE /shows/:id
export const showsManageRouter = Router();

showsManageRouter.patch(
  '/:id',
  requireAuth,
  requireRole('HALL_MANAGER', 'ADMIN'),
  async (req, res, next) => {
    try {
      const input = updateShowSchema.parse(req.body);
      const show = await updateShow(String(req.params['id']), req.user!.id, req.user!.role, input);
      res.json({ show });
    } catch (err: unknown) {
      if ((err as any)?.scheduling) {
        res.status(422).json({
          error: { code: (err as any).code, message: (err as Error).message },
        });
        return;
      }
      next(err);
    }
  }
);

showsManageRouter.delete(
  '/:id',
  requireAuth,
  requireRole('HALL_MANAGER', 'ADMIN'),
  async (req, res, next) => {
    try {
      const result = await deleteShow(String(req.params['id']), req.user!.id, req.user!.role);
      res.json(result);
    } catch (err: unknown) {
      if ((err as any)?.scheduling) {
        res.status(422).json({
          error: { code: (err as any).code, message: (err as Error).message },
        });
        return;
      }
      next(err);
    }
  }
);
