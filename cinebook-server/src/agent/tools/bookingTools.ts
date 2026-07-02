// src/agent/tools/bookingTools.ts
import { tool } from 'ai';
import { z } from 'zod';
import {
  theatreQuerySchema,
  getScreenInfoSchema,
  checkSeatAvailabilitySchema,
  holdSeatsToolSchema,
  releaseSeatsToolSchema,
  createBookingToolSchema,
  checkBookingStatusSchema,
  cancelBookingToolSchema,
  startPaymentToolSchema,
  promoApplySchema,
} from '../../schemas/index.js';
import { listTheatres } from '../../services/theatreService.js';
import { getScreenById } from '../../services/screenService.js';
import { getSeatAvailability } from '../../services/seatService.js';
import { holdSeats, releaseHold } from '../../services/holdService.js';
import {
  confirmBooking,
  getBookingById,
  cancelBooking,
  getUserBookings,
} from '../../services/bookingService.js';
import { initiatePayment } from '../../services/paymentService.js';
import { applyPromoCode } from '../../services/promoService.js';
import { withToolLogger } from '../toolLogger.js';

/**
 * Factory that creates the 12 booking tools bound to the authenticated userId + role.
 * Splitting into a factory (rather than a static object) ensures tool executes
 * close over the correct user identity without globals.
 */
export function createBookingTools(userId: string, role: string) {
  return {
    findTheatres: tool({
      description:
        'Find theatres that show a specific movie. Accepts optional movieId and city filters. Returns theatres with theatreId. Use to help user pick a location.',
      inputSchema: theatreQuerySchema,
      execute: withToolLogger('findTheatres', async (input) => {
        const theatres = await listTheatres(input);
        return { renderHint: 'text' as const, theatres };
      }),
    }),

    getScreenInfo: tool({
      description:
        'Get detailed info about a specific screen (seats layout, type, equipment) by screenId. Use after picking a show and needing screen details.',
      inputSchema: getScreenInfoSchema,
      execute: withToolLogger('getScreenInfo', async ({ screenId }) => {
        const screen = await getScreenById(screenId);
        if (!screen) throw new Error(`Screen ${screenId} not found`);
        return { renderHint: 'text' as const, screen };
      }),
    }),

    checkSeatAvailability: tool({
      description:
        'Get seat availability map for a show by showId. Returns all seats with state (free/held/booked), row, number, category, and price. Use before holdSeats. Chain: getShowtimes → showId → checkSeatAvailability → seatIds.',
      inputSchema: checkSeatAvailabilitySchema,
      execute: withToolLogger('checkSeatAvailability', async ({ showId }) => {
        const seats = await getSeatAvailability(showId);
        if (!seats) throw new Error(`Show ${showId} not found`);
        return { renderHint: 'seatMap' as const, showId, seats };
      }),
    }),

    holdSeats: tool({
      description:
        'Hold specific seats for 5 minutes for the current user. Requires showId and seatIds[]. Returns holdToken and expiresAt on success. MUST be called before createBooking. Returns failedSeatIds if any seat is already taken.',
      inputSchema: holdSeatsToolSchema,
      execute: withToolLogger('holdSeats', async ({ showId, seatIds }) => {
        const result = await holdSeats(showId, seatIds, userId);
        if ('failedSeatIds' in result) {
          return { renderHint: 'text' as const, success: false, failedSeatIds: result.failedSeatIds };
        }
        return {
          renderHint: 'text' as const,
          success: true,
          holdToken: result.holdToken,
          expiresAt: result.expiresAt,
        };
      }),
    }),

    releaseSeats: tool({
      description:
        'Release held seats early using holdToken from holdSeats. Use if the user changes their mind before booking. Requires showId, seatIds, and holdToken.',
      inputSchema: releaseSeatsToolSchema,
      execute: withToolLogger('releaseSeats', async ({ showId, seatIds, holdToken }) => {
        await releaseHold(showId, seatIds, userId, holdToken);
        return { renderHint: 'text' as const, released: true };
      }),
    }),

    createBooking: tool({
      description:
        'Confirm a booking after holdSeats succeeds. Requires showId, seatIds, holdToken. Optional promoCode for discount. Returns bookingId and totalCost. ALWAYS get explicit user confirmation before calling.',
      inputSchema: createBookingToolSchema,
      execute: withToolLogger('createBooking', async (input) => {
        const result = await confirmBooking(userId, input);
        return { renderHint: 'bookingSummary' as const, ...result };
      }),
    }),

    checkBookingStatus: tool({
      description:
        'Get status and details of a specific booking by bookingId. Use after createBooking to confirm, or when user asks "what is my booking status?".',
      inputSchema: checkBookingStatusSchema,
      execute: withToolLogger('checkBookingStatus', async ({ bookingId }) => {
        const booking = await getBookingById(bookingId, userId, role);
        if (!booking) throw new Error(`Booking ${bookingId} not found or access denied`);
        return { renderHint: 'bookingSummary' as const, booking };
      }),
    }),

    cancelBooking: tool({
      description:
        'Cancel a booking by bookingId. Only cancels bookings belonging to the current user. Refunds payment if the booking was paid.',
      inputSchema: cancelBookingToolSchema,
      execute: withToolLogger('cancelBooking', async ({ bookingId }) => {
        const result = await cancelBooking(bookingId, userId, role);
        return { renderHint: 'bookingSummary' as const, ...result };
      }),
    }),

    viewBookingHistory: tool({
      description:
        "List all of the current user's bookings, most recent first. Use when user asks 'show my bookings' or 'what have I booked?'.",
      inputSchema: z.object({}),
      execute: withToolLogger('viewBookingHistory', async () => {
        const bookings = await getUserBookings(userId);
        return { renderHint: 'bookingSummary' as const, bookings };
      }),
    }),

    startPayment: tool({
      description:
        'Initiate payment for a confirmed booking. Requires bookingId. cardNumber defaults to 4000 (always succeeds in test mode). Returns paymentId and transactionId. ALWAYS get user confirmation before paying.',
      inputSchema: startPaymentToolSchema,
      execute: withToolLogger('startPayment', async ({ bookingId, cardNumber }) => {
        const result = await initiatePayment(bookingId, cardNumber ?? '4000');
        return { renderHint: 'paymentResult' as const, ...result };
      }),
    }),

    confirmPayment: tool({
      description:
        'Confirm and process payment for a booking. Use when user explicitly says "confirm payment" or "pay now". Alias for startPayment.',
      inputSchema: startPaymentToolSchema,
      execute: withToolLogger('confirmPayment', async ({ bookingId, cardNumber }) => {
        const result = await initiatePayment(bookingId, cardNumber ?? '4000');
        return { renderHint: 'paymentResult' as const, ...result };
      }),
    }),

    applyPromoCode: tool({
      description:
        'Check if a promo code is valid and calculate the discounted amount. Requires code and amount (in paise). Returns discount and final amount. Use before createBooking when user has a promo code.',
      inputSchema: promoApplySchema,
      execute: withToolLogger('applyPromoCode', async ({ code, amount }) => {
        const result = await applyPromoCode(code, amount);
        return { renderHint: 'text' as const, ...result };
      }),
    }),
  };
}
