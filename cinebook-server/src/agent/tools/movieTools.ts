// src/agent/tools/movieTools.ts
import { tool } from 'ai';
import { z } from 'zod';
import {
  movieSearchSchema,
  getMovieDetailsSchema,
  getCastSchema,
  getReviewsSchema,
  suggestSimilarSchema,
  movieUpcomingSchema,
  showQuerySchema,
} from '../../schemas/index.js';
import {
  searchMovies,
  getMovieById,
  getMovieReviews,
  getSimilarMovies,
  getTrendingMovies,
  getUpcomingMovies,
  getAllGenres,
  getAllLanguages,
} from '../../services/movieService.js';
import { getShows } from '../../services/showService.js';
import { withToolLogger } from '../toolLogger.js';

/**
 * 10 movie-discovery tools — stateless, no user context needed.
 * Each execute() calls a Phase 1 service and returns { renderHint, ...data }.
 */
export const movieTools = {
  searchMovies: tool({
    description:
      'Search for movies by title, genre, language, age rating, screen type, format, or chain. Returns a list of matching movies with movieId. Use when the user mentions a movie title or asks to browse movies.',
    inputSchema: movieSearchSchema,
    execute: withToolLogger('searchMovies', async (input) => {
      const movies = await searchMovies(input);
      return { renderHint: 'movieList' as const, movies };
    }),
  }),

  getMovieDetails: tool({
    description:
      'Get full details for a single movie by its ID, including genres and reviews. Use after searchMovies returns a movieId and the user wants more info.',
    inputSchema: getMovieDetailsSchema,
    execute: withToolLogger('getMovieDetails', async ({ movieId }) => {
      const movie = await getMovieById(movieId);
      if (!movie) throw new Error(`Movie ${movieId} not found`);
      return { renderHint: 'movieCard' as const, movie };
    }),
  }),

  getCast: tool({
    description:
      'Get the cast list for a movie by its ID. Use when the user asks "who is in this movie?" or wants cast details.',
    inputSchema: getCastSchema,
    execute: withToolLogger('getCast', async ({ movieId }) => {
      const movie = await getMovieById(movieId);
      if (!movie) throw new Error(`Movie ${movieId} not found`);
      return { renderHint: 'text' as const, cast: movie.cast, movieTitle: movie.title };
    }),
  }),

  getReviews: tool({
    description:
      'Get user reviews for a movie by its ID. Use when the user asks about ratings or reviews.',
    inputSchema: getReviewsSchema,
    execute: withToolLogger('getReviews', async ({ movieId }) => {
      const reviews = await getMovieReviews(movieId);
      return { renderHint: 'text' as const, reviews };
    }),
  }),

  getShowtimes: tool({
    description:
      'Get showtimes for a movie. Accepts: movieId, date (YYYY-MM-DD), city, screenType (STANDARD|IMAX|FOURDX|DOLBY_ATMOS), format (2D|3D). Returns shows with showId. Chain showId to checkSeatAvailability.',
    inputSchema: showQuerySchema,
    execute: withToolLogger('getShowtimes', async (input) => {
      const shows = await getShows(input);
      return { renderHint: 'showtimes' as const, shows };
    }),
  }),

  suggestSimilar: tool({
    description:
      'Suggest movies similar to a given movieId based on shared genres. Use when user says "show me something like X" or a movie is sold out.',
    inputSchema: suggestSimilarSchema,
    execute: withToolLogger('suggestSimilar', async ({ movieId }) => {
      const movies = await getSimilarMovies(movieId);
      return { renderHint: 'movieList' as const, movies };
    }),
  }),

  getTrending: tool({
    description:
      'Get the top trending movies right now based on recent bookings. Use when the user asks "what is popular?" or "what is trending?".',
    inputSchema: z.object({}),
    execute: withToolLogger('getTrending', async () => {
      const movies = await getTrendingMovies();
      return { renderHint: 'movieList' as const, movies };
    }),
  }),

  getUpcoming: tool({
    description:
      'Get upcoming movies releasing soon. Use when the user asks "what movies are coming soon?" or "upcoming releases".',
    inputSchema: movieUpcomingSchema,
    execute: withToolLogger('getUpcoming', async (input) => {
      const movies = await getUpcomingMovies(input.date);
      return { renderHint: 'movieList' as const, movies };
    }),
  }),

  listLanguages: tool({
    description:
      'List all available movie languages in the system. Use when the user wants to know what languages are available or to filter by language.',
    inputSchema: z.object({}),
    execute: withToolLogger('listLanguages', async () => {
      const languages = await getAllLanguages();
      return { renderHint: 'text' as const, languages };
    }),
  }),

  listGenres: tool({
    description:
      'List all available movie genres. Use when the user wants to browse by genre or asks "what genres are available?".',
    inputSchema: z.object({}),
    execute: withToolLogger('listGenres', async () => {
      const genres = await getAllGenres();
      return { renderHint: 'text' as const, genres: genres.map((g) => g.name) };
    }),
  }),
};
