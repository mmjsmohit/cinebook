import { z } from 'zod';

// ─── Movie Schemas ───────────────────────────────────────────────────────────

export const movieSearchSchema = z.object({
  q: z.string().optional(),
  genre: z.string().optional(),
  chain: z.string().optional(),
  screenType: z.enum(['STANDARD', 'IMAX', 'FOURDX', 'DOLBY_ATMOS']).optional(),
  format: z.string().optional(),
  language: z.string().optional(),
  ageRating: z.string().optional(),
  releaseDate: z.string().optional(),
});

export const movieUpcomingSchema = z.object({
  date: z.string().optional(),
});

// ─── Theatre Schemas ─────────────────────────────────────────────────────────

export const theatreQuerySchema = z.object({
  movieId: z.string().optional(),
  city: z.string().optional(),
});

// ─── Show Schemas ────────────────────────────────────────────────────────────

export const showQuerySchema = z.object({
  movieId: z.string().optional(),
  date: z.string().optional(),
  city: z.string().optional(),
  screenType: z.enum(['STANDARD', 'IMAX', 'FOURDX', 'DOLBY_ATMOS']).optional(),
  format: z.string().optional(),
});

export const holdRequestSchema = z.object({
  seatIds: z.array(z.string()).min(1).max(10),
});

export const releaseHoldSchema = z.object({
  holdToken: z.string(),
});

// ─── Booking Schemas ─────────────────────────────────────────────────────────

export const confirmBookingSchema = z.object({
  showId: z.string(),
  seatIds: z.array(z.string()).min(1).max(10),
  holdToken: z.string(),
  promoCode: z.string().optional(),
});

// ─── Payment Schemas ─────────────────────────────────────────────────────────

export const initiatePaymentSchema = z.object({
  bookingId: z.string(),
  cardNumber: z.string().min(4).max(19),
});

// ─── Promo Schemas ───────────────────────────────────────────────────────────

export const promoApplySchema = z.object({
  code: z.string(),
  amount: z.number().int().positive(),
});

// ─── Hall-Manager Show Scheduling ────────────────────────────────────────────

export const createShowSchema = z.object({
  movieId: z.string(),
  startTime: z.string().datetime({ offset: true }),
  basePrice: z.number().int().positive(),
  language: z.string(),
  format: z.string(),
});

export const updateShowSchema = z.object({
  startTime: z.string().datetime({ offset: true }).optional(),
  basePrice: z.number().int().positive().optional(),
  language: z.string().optional(),
  format: z.string().optional(),
});

export const hallShowQuerySchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
});

// ─── Type Exports ────────────────────────────────────────────────────────────

export type MovieSearchInput = z.infer<typeof movieSearchSchema>;
export type TheatreQueryInput = z.infer<typeof theatreQuerySchema>;
export type ShowQueryInput = z.infer<typeof showQuerySchema>;
export type HoldRequestInput = z.infer<typeof holdRequestSchema>;
export type ReleaseHoldInput = z.infer<typeof releaseHoldSchema>;
export type ConfirmBookingInput = z.infer<typeof confirmBookingSchema>;
export type InitiatePaymentInput = z.infer<typeof initiatePaymentSchema>;
export type PromoApplyInput = z.infer<typeof promoApplySchema>;
export type CreateShowInput = z.infer<typeof createShowSchema>;
export type UpdateShowInput = z.infer<typeof updateShowSchema>;

// ─── Agent / Chat Schemas ────────────────────────────────────────────────────

export const agentRunSchema = z.object({
  message: z.string().min(1).max(4000),
  threadId: z.string().optional(),
});

export const delegateSchema = z.object({
  request: z.string(),
  userId: z.string(),
});

// Tool-specific input schemas (reused as tool inputSchema in the agent registry)

export const getMovieDetailsSchema = z.object({ movieId: z.string() });
export const getCastSchema = z.object({ movieId: z.string() });
export const getReviewsSchema = z.object({ movieId: z.string() });
export const suggestSimilarSchema = z.object({ movieId: z.string() });
export const getScreenInfoSchema = z.object({ screenId: z.string() });
export const checkSeatAvailabilitySchema = z.object({ showId: z.string() });

export const holdSeatsToolSchema = z.object({
  showId: z.string(),
  seatIds: z.array(z.string()).min(1).max(10),
});

export const releaseSeatsToolSchema = z.object({
  showId: z.string(),
  seatIds: z.array(z.string()).min(1).max(10),
  holdToken: z.string(),
});

export const createBookingToolSchema = z.object({
  showId: z.string(),
  seatIds: z.array(z.string()).min(1).max(10),
  holdToken: z.string(),
  promoCode: z.string().optional(),
});

export const checkBookingStatusSchema = z.object({ bookingId: z.string() });
export const cancelBookingToolSchema = z.object({ bookingId: z.string() });

export const startPaymentToolSchema = z.object({
  bookingId: z.string(),
  cardNumber: z.string().min(4).max(19).default('4000'),
});

export const updatePreferencesSchema = z.object({
  prefs: z.record(z.string(), z.unknown()),
});

export const contactSupportSchema = z.object({
  message: z.string(),
  category: z.enum(['booking', 'payment', 'general']).default('general'),
});

// Agent type exports
export type AgentRunInput = z.infer<typeof agentRunSchema>;
export type DelegateInput = z.infer<typeof delegateSchema>;

// ─── Admin Schemas ───────────────────────────────────────────────────────────

export const adminUserPatchSchema = z.object({
  name: z.string().optional(),
  phone: z.string().optional(),
});

export const adminUserRoleSchema = z.object({
  role: z.enum(['CUSTOMER', 'HALL_MANAGER', 'ADMIN']),
});

export const adminMovieCreateSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  runtimeMin: z.number().int().positive(),
  cast: z.array(z.string()).default([]),
  posterUrl: z.string().url().optional(),
  trailerUrl: z.string().url().optional(),
  releaseDate: z.string().datetime({ offset: true }),
  ageRating: z.enum(['U', 'UA', 'A']),
  languages: z.array(z.string()).min(1),
  genreIds: z.array(z.string()).default([]),
});

export const adminMoviePatchSchema = adminMovieCreateSchema.partial();

export const adminGenreUpdateSchema = z.object({
  imageUrl: z.string().url().optional().nullable(),
});

export const adminTheatreCreateSchema = z.object({
  chain: z.string().min(1),
  name: z.string().min(1),
  city: z.string().min(1),
  address: z.string().min(1),
});

export const adminTheatrePatchSchema = adminTheatreCreateSchema.partial();

export const adminScreenCreateSchema = z.object({
  theatreId: z.string(),
  name: z.string().min(1),
  type: z.enum(['STANDARD', 'IMAX', 'FOURDX', 'DOLBY_ATMOS']),
  format: z.string(), // 2D | 3D
  equipment: z.array(z.string()).default([]),
  managerId: z.string().optional(),
  seats: z.array(z.object({
    row: z.string(),
    number: z.number().int().positive(),
    category: z.enum(['FRONT', 'STANDARD', 'PREMIUM', 'RECLINER']),
  })).optional(),
});

export const adminScreenPatchSchema = z.object({
  name: z.string().min(1).optional(),
  type: z.enum(['STANDARD', 'IMAX', 'FOURDX', 'DOLBY_ATMOS']).optional(),
  format: z.string().optional(),
  equipment: z.array(z.string()).optional(),
  managerId: z.string().nullable().optional(),
  seats: z.array(z.object({
    row: z.string(),
    number: z.number().int().positive(),
    category: z.enum(['FRONT', 'STANDARD', 'PREMIUM', 'RECLINER']),
  })).optional(),
});

export const adminShowCreateSchema = z.object({
  movieId: z.string(),
  screenId: z.string(),
  startTime: z.string().datetime({ offset: true }),
  basePrice: z.number().int().positive(),
  language: z.string(),
  format: z.string(),
});

export const adminReportsQuerySchema = z.object({
  range: z.enum(['daily', 'weekly', 'monthly']),
});

export const adminActivityQuerySchema = z.object({
  actorId: z.string().optional(),
  from: z.string().datetime({ offset: true }).optional(),
  to: z.string().datetime({ offset: true }).optional(),
  limit: z.coerce.number().int().positive().default(100),
});

// Admin type exports
export type AdminUserPatchInput = z.infer<typeof adminUserPatchSchema>;
export type AdminUserRoleInput = z.infer<typeof adminUserRoleSchema>;
export type AdminMovieCreateInput = z.infer<typeof adminMovieCreateSchema>;
export type AdminMoviePatchInput = z.infer<typeof adminMoviePatchSchema>;
export type AdminTheatreCreateInput = z.infer<typeof adminTheatreCreateSchema>;
export type AdminTheatrePatchInput = z.infer<typeof adminTheatrePatchSchema>;
export type AdminScreenCreateInput = z.infer<typeof adminScreenCreateSchema>;
export type AdminScreenPatchInput = z.infer<typeof adminScreenPatchSchema>;
export type AdminShowCreateInput = z.infer<typeof adminShowCreateSchema>;
export type AdminReportsQueryInput = z.infer<typeof adminReportsQuerySchema>;
export type AdminActivityQueryInput = z.infer<typeof adminActivityQuerySchema>;
export type AdminGenreUpdateInput = z.infer<typeof adminGenreUpdateSchema>;
