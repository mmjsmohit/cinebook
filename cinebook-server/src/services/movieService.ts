import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import type { MovieSearchInput } from '../schemas/index.js';
import type { Prisma } from '@prisma/client';

const CATEGORY_MULTIPLIER = {
  FRONT: 0.8,
  STANDARD: 1.0,
  PREMIUM: 1.3,
  RECLINER: 1.6,
} as const;

export { CATEGORY_MULTIPLIER };

export async function searchMovies(input: MovieSearchInput) {
  logger.info('movieService.searchMovies', { input });

  const where: Prisma.MovieWhereInput = {};

  if (input.q) {
    where.title = { contains: input.q, mode: 'insensitive' };
  }
  if (input.language) {
    where.languages = { has: input.language };
  }
  if (input.ageRating) {
    where.ageRating = input.ageRating;
  }
  if (input.releaseDate) {
    const d = new Date(input.releaseDate);
    where.releaseDate = { gte: d };
  }
  if (input.genre || input.chain || input.screenType || input.format) {
    // Genre filter: join through genres relation
    if (input.genre) {
      where.genres = { some: { name: { equals: input.genre, mode: 'insensitive' } } };
    }
    // Chain / screenType / format: movie must have at least one show matching
    const showFilter: Prisma.ShowWhereInput = {};
    if (input.chain) {
      showFilter.screen = { theatre: { chain: { equals: input.chain, mode: 'insensitive' } } };
    }
    if (input.screenType) {
      showFilter.screen = {
        ...showFilter.screen as object,
        type: input.screenType,
      };
    }
    if (input.format) {
      showFilter.format = input.format;
    }
    if (Object.keys(showFilter).length > 0) {
      where.shows = { some: showFilter };
    }
  }

  const movies = await prisma.movie.findMany({
    where,
    include: { genres: true },
    orderBy: { releaseDate: 'desc' },
    take: 50,
  });
  return movies;
}

export async function getMovieById(id: string) {
  logger.info('movieService.getMovieById', { id });
  const movie = await prisma.movie.findUnique({
    where: { id },
    include: { genres: true, reviews: true },
  });
  if (!movie) return null;
  return movie;
}

export async function getMovieReviews(movieId: string) {
  logger.info('movieService.getMovieReviews', { movieId });
  return prisma.review.findMany({ where: { movieId }, orderBy: { id: 'desc' } });
}

export async function getSimilarMovies(movieId: string) {
  logger.info('movieService.getSimilarMovies', { movieId });
  const movie = await prisma.movie.findUnique({
    where: { id: movieId },
    include: { genres: true },
  });
  if (!movie) return [];
  const genreIds = movie.genres.map((g) => g.id);
  return prisma.movie.findMany({
    where: {
      id: { not: movieId },
      genres: { some: { id: { in: genreIds } } },
    },
    include: { genres: true },
    take: 10,
  });
}

export async function getTrendingMovies() {
  logger.info('movieService.getTrendingMovies');
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  // Group bookings by movieId (via show) in the last 7 days
  const grouped = await prisma.booking.groupBy({
    by: ['showId'],
    where: { createdAt: { gte: sevenDaysAgo } },
    _count: { id: true },
  });

  const showIds = grouped.map((g) => g.showId);
  if (showIds.length === 0) {
    return prisma.movie.findMany({ include: { genres: true }, take: 10 });
  }

  const shows = await prisma.show.findMany({
    where: { id: { in: showIds } },
    select: { movieId: true, id: true },
  });

  const countByMovie: Record<string, number> = {};
  for (const g of grouped) {
    const show = shows.find((s) => s.id === g.showId);
    if (show) {
      countByMovie[show.movieId] = (countByMovie[show.movieId] ?? 0) + (g._count.id);
    }
  }

  const topMovieIds = Object.entries(countByMovie)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([id]) => id);

  const movies = await prisma.movie.findMany({
    where: { id: { in: topMovieIds } },
    include: { genres: true },
  });

  // Preserve trending order
  return topMovieIds.map((id) => movies.find((m) => m.id === id)!).filter(Boolean);
}

export async function getUpcomingMovies(afterDate?: string) {
  logger.info('movieService.getUpcomingMovies', { afterDate });
  const from = afterDate ? new Date(afterDate) : new Date();
  return prisma.movie.findMany({
    where: { releaseDate: { gte: from } },
    include: { genres: true },
    orderBy: { releaseDate: 'asc' },
    take: 20,
  });
}

export async function getAllGenres() {
  logger.info('movieService.getAllGenres');
  return prisma.genre.findMany({ orderBy: { name: 'asc' } });
}

export async function getAllLanguages() {
  logger.info('movieService.getAllLanguages');
  const movies = await prisma.movie.findMany({ select: { languages: true } });
  const set = new Set<string>();
  for (const m of movies) {
    for (const l of m.languages) set.add(l);
  }
  return Array.from(set).sort();
}
