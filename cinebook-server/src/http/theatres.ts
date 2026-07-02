import { Router } from 'express';
import { listTheatres } from '../services/theatreService.js';
import { theatreQuerySchema } from '../schemas/index.js';

const router = Router();

// GET /theatres?movieId=&city=
router.get('/', async (req, res, next) => {
  try {
    const input = theatreQuerySchema.parse(req.query);
    const theatres = await listTheatres(input);
    res.json({ theatres });
  } catch (err) {
    next(err);
  }
});

export default router;
