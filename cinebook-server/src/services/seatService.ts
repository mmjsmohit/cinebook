import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import { CATEGORY_MULTIPLIER } from './movieService.js';
import type { SeatCategory } from '@prisma/client';
import { getHeldSeatIds } from './holdService.js';

/** Return availability + price of every seat for a show (polling endpoint) */
export async function getSeatAvailability(showId: string) {
  logger.info('seatService.getSeatAvailability', { showId });

  const show = await prisma.show.findUnique({
    where: { id: showId },
    include: {
      screen: { include: { seats: { orderBy: [{ row: 'asc' }, { number: 'asc' }] } } },
      bookedSeats: { select: { seatId: true } },
    },
  });

  if (!show) return null;

  const bookedSeatIds = new Set(show.bookedSeats.map((bs) => bs.seatId));
  const allSeatIds = show.screen.seats.map((s) => s.id);
  const heldSeatIds = await getHeldSeatIds(showId, allSeatIds);

  return show.screen.seats.map((seat) => {
    const multiplier = CATEGORY_MULTIPLIER[seat.category as SeatCategory];
    const price = Math.round(show.basePrice * multiplier);
    let state: 'free' | 'held' | 'booked';
    if (bookedSeatIds.has(seat.id)) {
      state = 'booked';
    } else if (heldSeatIds.has(seat.id)) {
      state = 'held';
    } else {
      state = 'free';
    }
    return {
      id: seat.id,
      row: seat.row,
      number: seat.number,
      category: seat.category,
      state,
      price,
    };
  });
}

/** Return availability summary for multiple shows (for UI color coding) */
export async function getBatchSeatAvailability(showIds: string[]) {
  const shows = await prisma.show.findMany({
    where: { id: { in: showIds } },
    include: {
      screen: { include: { seats: { select: { id: true } } } },
      bookedSeats: { select: { seatId: true } },
    },
  });

  const availability: Record<string, number> = {};

  for (const show of shows) {
    const bookedCount = show.bookedSeats.length;
    const allSeatIds = show.screen.seats.map((s) => s.id);
    const heldSeatIds = await getHeldSeatIds(show.id, allSeatIds);
    
    const unavailableCount = bookedCount + heldSeatIds.size;
    const capacity = allSeatIds.length;
    
    availability[show.id] = capacity > 0 ? 1.0 - (unavailableCount / capacity) : 0;
  }
  return availability;
}
