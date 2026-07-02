import { Router } from 'express';
import {
  searchMovies,
  getMovieById,
  getMovieReviews,
  getSimilarMovies,
  getTrendingMovies,
  getUpcomingMovies,
  getAllGenres,
  getAllLanguages,
} from '../services/movieService.js';
import { movieSearchSchema, movieUpcomingSchema } from '../schemas/index.js';

const router = Router();

// GET /movies
router.get('/', async (req, res, next) => {
  try {
    const input = movieSearchSchema.parse(req.query);
    const movies = await searchMovies(input);
    res.json({ movies });
  } catch (err) {
    next(err);
  }
});

// GET /movies/trending
router.get('/trending', async (_req, res, next) => {
  try {
    const movies = await getTrendingMovies();
    res.json({ movies });
  } catch (err) {
    next(err);
  }
});

// GET /movies/upcoming
router.get('/upcoming', async (req, res, next) => {
  try {
    const { date } = movieUpcomingSchema.parse(req.query);
    const movies = await getUpcomingMovies(date);
    res.json({ movies });
  } catch (err) {
    next(err);
  }
});

// GET /movies/:id
router.get('/:id', async (req, res, next) => {
  try {
    const movie = await getMovieById(req.params.id!);
    if (!movie) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Movie not found' } });
      return;
    }
    res.json({ movie });
  } catch (err) {
    next(err);
  }
});

// GET /movies/:id/reviews
router.get('/:id/reviews', async (req, res, next) => {
  try {
    const reviews = await getMovieReviews(req.params.id!);
    res.json({ reviews });
  } catch (err) {
    next(err);
  }
});

// GET /movies/:id/similar
router.get('/:id/similar', async (req, res, next) => {
  try {
    const movies = await getSimilarMovies(req.params.id!);
    res.json({ movies });
  } catch (err) {
    next(err);
  }
});

export default router;

// ── Separate routers for /genres and /languages ──────────────────────────────

export const genresRouter = Router();
genresRouter.get('/', async (_req, res, next) => {
  try {
    const genres = await getAllGenres();
    res.json({ genres });
  } catch (err) {
    next(err);
  }
});

export const languagesRouter = Router();
languagesRouter.get('/', async (_req, res, next) => {
  try {
    const languages = await getAllLanguages();
    res.json({ languages });
  } catch (err) {
    next(err);
  }
});
