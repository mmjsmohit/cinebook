import { Router } from 'express';
import { requireAuth, requireRole } from '../middlewares/authMiddleware.js';
import {
  listUsers, patchUser, disableUser, assignRole,
  createMovie, patchMovie,
  createTheatre, patchTheatre,
  createScreen, patchScreen,
  createAdminShow,
  getReports,
} from '../services/adminService.js';
import { getActivityLog } from '../services/activityLogService.js';
import {
  adminUserPatchSchema, adminUserRoleSchema,
  adminMovieCreateSchema, adminMoviePatchSchema,
  adminTheatreCreateSchema, adminTheatrePatchSchema,
  adminScreenCreateSchema, adminScreenPatchSchema,
  adminShowCreateSchema,
  adminReportsQuerySchema, adminActivityQuerySchema,
} from '../schemas/index.js';

const router = Router();

// All admin routes require ADMIN role
router.use(requireAuth, requireRole('ADMIN'));

// ─── Users ───────────────────────────────────────────────────────────────────

router.get('/users', async (_req, res, next) => {
  try {
    const users = await listUsers();
    res.json({ users });
  } catch (err) { next(err); }
});

router.patch('/users/:id', async (req, res, next) => {
  try {
    const data = adminUserPatchSchema.parse(req.body);
    const user = await patchUser(req.user!.id, req.params.id!, data);
    res.json({ user });
  } catch (err) { next(err); }
});

router.post('/users/:id/disable', async (req, res, next) => {
  try {
    const user = await disableUser(req.user!.id, req.params.id!);
    res.json({ user });
  } catch (err) { next(err); }
});

router.post('/users/:id/role', async (req, res, next) => {
  try {
    const data = adminUserRoleSchema.parse(req.body);
    const user = await assignRole(req.user!.id, req.params.id!, data);
    res.json({ user });
  } catch (err) { next(err); }
});

// ─── Movies ──────────────────────────────────────────────────────────────────

router.post('/movies', async (req, res, next) => {
  try {
    const data = adminMovieCreateSchema.parse(req.body);
    const movie = await createMovie(req.user!.id, data);
    res.status(201).json({ movie });
  } catch (err) { next(err); }
});

router.patch('/movies/:id', async (req, res, next) => {
  try {
    const data = adminMoviePatchSchema.parse(req.body);
    const movie = await patchMovie(req.user!.id, req.params.id!, data);
    res.json({ movie });
  } catch (err) { next(err); }
});

// ─── Theatres ────────────────────────────────────────────────────────────────

router.post('/theatres', async (req, res, next) => {
  try {
    const data = adminTheatreCreateSchema.parse(req.body);
    const theatre = await createTheatre(req.user!.id, data);
    res.status(201).json({ theatre });
  } catch (err) { next(err); }
});

router.patch('/theatres/:id', async (req, res, next) => {
  try {
    const data = adminTheatrePatchSchema.parse(req.body);
    const theatre = await patchTheatre(req.user!.id, req.params.id!, data);
    res.json({ theatre });
  } catch (err) { next(err); }
});

// ─── Screens ─────────────────────────────────────────────────────────────────

router.post('/screens', async (req, res, next) => {
  try {
    const data = adminScreenCreateSchema.parse(req.body);
    const screen = await createScreen(req.user!.id, data);
    res.status(201).json({ screen });
  } catch (err) { next(err); }
});

router.patch('/screens/:id', async (req, res, next) => {
  try {
    const data = adminScreenPatchSchema.parse(req.body);
    const screen = await patchScreen(req.user!.id, req.params.id!, data);
    res.json({ screen });
  } catch (err) { next(err); }
});

// ─── Shows (override) ───────────────────────────────────────────────────────

router.post('/shows', async (req, res, next) => {
  try {
    const data = adminShowCreateSchema.parse(req.body);
    const show = await createAdminShow(req.user!.id, data);
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
});

// ─── Reports ─────────────────────────────────────────────────────────────────

router.get('/reports', async (req, res, next) => {
  try {
    const input = adminReportsQuerySchema.parse(req.query);
    const report = await getReports(input);
    res.json({ report });
  } catch (err) { next(err); }
});

// ─── Activity Log ────────────────────────────────────────────────────────────

router.get('/activity-log', async (req, res, next) => {
  try {
    const filters = adminActivityQuerySchema.parse(req.query);
    const cleanFilters = Object.fromEntries(Object.entries(filters).filter(([_, v]) => v !== undefined));
    const logs = await getActivityLog(cleanFilters);
    res.json({ logs });
  } catch (err) { next(err); }
});

export default router;
