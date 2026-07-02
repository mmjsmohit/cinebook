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
