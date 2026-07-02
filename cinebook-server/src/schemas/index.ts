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
