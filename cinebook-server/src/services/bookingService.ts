import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import { getSeatOwnerToken } from './holdService.js';
import { releaseHold } from './holdService.js';
import { applyPromoCode } from './promoService.js';
import { CATEGORY_MULTIPLIER } from './movieService.js';
import type { SeatCategory } from '@prisma/client';
import type { ConfirmBookingInput } from '../schemas/index.js';
import { Prisma } from '@prisma/client';

export async function confirmBooking(userId: string, input: ConfirmBookingInput) {
  logger.info('bookingService.confirmBooking', { userId, showId: input.showId });

  const { showId, seatIds, holdToken, promoCode } = input;

  // 1. Fetch show + seats
  const show = await prisma.show.findUnique({
    where: { id: showId },
    include: { 
      movie: true,
      screen: { include: { seats: { where: { id: { in: seatIds } } } } } 
    },
  });
  if (!show) {
    throw Object.assign(new Error('Show not found'), { code: 'NOT_FOUND' });
  }
  if (show.screen.seats.length !== seatIds.length) {
    throw Object.assign(new Error('One or more seat IDs are invalid for this show'), {
      code: 'INVALID_SEATS',
    });
  }

  // 2. Re-verify Redis holds
  const ownerToken = `${userId}:${holdToken}`;
  const lapseIds: string[] = [];
  for (const seatId of seatIds) {
    const stored = await getSeatOwnerToken(showId, seatId);
    if (stored !== ownerToken) lapseIds.push(seatId);
  }
  if (lapseIds.length > 0) {
    throw Object.assign(new Error('Hold lapsed or does not belong to you'), {
      code: 'HOLD_LAPSED',
      details: { lapseIds },
    });
  }

  // 3. Compute prices
  const seatPrices = show.screen.seats.map((seat) => {
    const multiplier = CATEGORY_MULTIPLIER[seat.category as SeatCategory];
    return { seatId: seat.id, price: Math.round(show.basePrice * multiplier) };
  });

  let baseCost = seatPrices.reduce((sum, sp) => sum + sp.price, 0);
  let totalCost = Math.round(baseCost * 1.18);

  // 4. Apply promo if provided
  let discountApplied = 0;
  if (promoCode) {
    const result = await applyPromoCode(promoCode, totalCost);
    if (result.valid) {
      discountApplied = result.discount;
      totalCost = result.discounted;
    }
  }

  // 5. Postgres transaction — insert Booking + BookedSeats
  let booking;
  try {
    booking = await prisma.$transaction(async (tx) => {
      const b = await tx.booking.create({
        data: {
          userId,
          showId,
          status: 'PENDING',
          totalCost,
          promoCode: promoCode && discountApplied > 0 ? promoCode : null,
          discountAmount: discountApplied > 0 ? discountApplied : null,
          seats: {
            create: seatPrices.map((sp) => ({
              showId,
              seatId: sp.seatId,
              pricePaid: sp.price,
            })),
          },
        },
        include: { seats: true },
      });
      return b;
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === 'P2002'
    ) {
      // Unique constraint on (showId, seatId) — someone committed first
      throw Object.assign(new Error('One or more seats were just booked by another user'), {
        code: 'SEAT_TAKEN',
      });
    }
    throw err;
  }

  // 6. Release holds
  await releaseHold(showId, seatIds, userId, holdToken);

  logger.info('bookingService.confirmBooking.success', { bookingId: booking.id, totalCost });
  return { 
    bookingId: booking.id, 
    totalCost, 
    discountApplied, 
    status: booking.status,
    movieTitle: show.movie.title,
    seats: seatIds,
  };
}

export async function getBookingById(bookingId: string, userId: string, role: string) {
  logger.info('bookingService.getBookingById', { bookingId, userId });
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { 
      seats: { include: { seat: true } }, 
      payment: true,
      show: {
        include: {
          movie: true,
          screen: {
            include: { theatre: true }
          }
        }
      }
    },
  });
  if (!booking) return null;
  if (booking.userId !== userId && role !== 'ADMIN') return null;
  return booking;
}

export async function cancelBooking(bookingId: string, userId: string, role: string) {
  logger.info('bookingService.cancelBooking', { bookingId, userId });

  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { payment: true },
  });
  if (!booking) throw Object.assign(new Error('Booking not found'), { code: 'NOT_FOUND' });
  if (booking.userId !== userId && role !== 'ADMIN') {
    throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' });
  }
  if (booking.status === 'CANCELLED') {
    throw Object.assign(new Error('Booking is already cancelled'), { code: 'ALREADY_CANCELLED' });
  }

  await prisma.$transaction(async (tx) => {
    await tx.booking.update({ where: { id: bookingId }, data: { status: 'CANCELLED' } });
    await tx.bookedSeat.deleteMany({ where: { bookingId } });
    // Refund payment if paid
    if (booking.payment && booking.payment.status === 'SUCCESS') {
      await tx.payment.update({
        where: { id: booking.payment.id },
        data: { status: 'REFUNDED' },
      });
    }
  });

  return { bookingId, status: 'CANCELLED' };
}

export async function getUserBookings(userId: string) {
  logger.info('bookingService.getUserBookings', { userId });
  return prisma.booking.findMany({
    where: { userId },
    include: { 
      seats: true, 
      payment: true,
      show: {
        include: {
          movie: true,
          screen: {
            include: { theatre: true }
          }
        }
      }
    },
    orderBy: { createdAt: 'desc' },
  });
}
