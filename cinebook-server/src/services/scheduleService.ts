import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import type { Prisma } from '@prisma/client';
import type { CreateShowInput, UpdateShowInput } from '../schemas/index.js';

const MAX_DAYS_AHEAD = 30;
const MIN_GAP_MINUTES = 30;

function schedulingError(code: string, message: string): never {
  throw Object.assign(new Error(message), { code, scheduling: true });
}

export async function getShowsForScreen(
  screenId: string,
  from?: string,
  to?: string
) {
  logger.info('scheduleService.getShowsForScreen', { screenId, from, to });
  const where: Prisma.ShowWhereInput = { screenId };
  if (from || to) {
    where.startTime = {
      ...(from ? { gte: new Date(from) } : {}),
      ...(to ? { lte: new Date(to) } : {}),
    };
  }
  return prisma.show.findMany({
    where,
    include: { movie: { select: { id: true, title: true, runtimeMin: true } } },
    orderBy: { startTime: 'asc' },
  });
}

export async function createShow(
  screenId: string,
  managerId: string,
  managerRole: string,
  input: CreateShowInput
) {
  logger.info('scheduleService.createShow', { screenId, managerId });

  // Fetch screen + movie
  const screen = await prisma.screen.findUnique({ where: { id: screenId } });
  if (!screen) schedulingError('SCREEN_NOT_FOUND', 'Screen not found');

  // Manager must own the screen (ADMIN bypasses)
  if (managerRole !== 'ADMIN' && screen.managerId !== managerId) {
    schedulingError('NOT_YOUR_SCREEN', 'You are not the manager of this screen');
  }

  const movie = await prisma.movie.findUnique({ where: { id: input.movieId } });
  if (!movie) schedulingError('MOVIE_NOT_FOUND', 'Movie not found');

  const startTime = new Date(input.startTime);
  const endTime = new Date(startTime.getTime() + movie.runtimeMin * 60 * 1000);

  // Start must be ≤ 30 days ahead
  const maxAhead = new Date(Date.now() + MAX_DAYS_AHEAD * 24 * 60 * 60 * 1000);
  if (startTime > maxAhead) {
    schedulingError('TOO_FAR_AHEAD', `Shows can only be scheduled up to ${MAX_DAYS_AHEAD} days in advance`);
  }

  // Check overlap + 30-min gap
  await validateGapAndOverlap(screenId, startTime, endTime, null);

  const show = await prisma.show.create({
    data: {
      movieId: input.movieId,
      screenId,
      startTime,
      endTime,
      basePrice: input.basePrice,
      language: input.language,
      format: input.format,
    },
    include: { movie: { select: { title: true } }, screen: { select: { name: true } } },
  });

  logger.info('scheduleService.createShow.success', { showId: show.id });
  return show;
}

export async function updateShow(
  showId: string,
  managerId: string,
  managerRole: string,
  input: UpdateShowInput
) {
  logger.info('scheduleService.updateShow', { showId, managerId });

  const show = await prisma.show.findUnique({
    where: { id: showId },
    include: { screen: true, movie: true, bookedSeats: { take: 1 } },
  });
  if (!show) schedulingError('SHOW_NOT_FOUND', 'Show not found');

  if (show.bookedSeats.length > 0) {
    schedulingError('HAS_BOOKINGS', 'Cannot edit a show that has existing bookings');
  }

  if (managerRole !== 'ADMIN' && show.screen.managerId !== managerId) {
    schedulingError('NOT_YOUR_SCREEN', 'You are not the manager of this screen');
  }

  let startTime = input.startTime ? new Date(input.startTime) : show.startTime;
  let endTime = new Date(startTime.getTime() + show.movie.runtimeMin * 60 * 1000);

  if (input.startTime) {
    const maxAhead = new Date(Date.now() + MAX_DAYS_AHEAD * 24 * 60 * 60 * 1000);
    if (startTime > maxAhead) {
      schedulingError('TOO_FAR_AHEAD', `Shows can only be scheduled up to ${MAX_DAYS_AHEAD} days in advance`);
    }
    await validateGapAndOverlap(show.screenId, startTime, endTime, showId);
  }

  return prisma.show.update({
    where: { id: showId },
    data: {
      startTime,
      endTime,
      ...(input.basePrice ? { basePrice: input.basePrice } : {}),
      ...(input.language ? { language: input.language } : {}),
      ...(input.format ? { format: input.format } : {}),
    },
  });
}

export async function deleteShow(
  showId: string,
  managerId: string,
  managerRole: string
) {
  logger.info('scheduleService.deleteShow', { showId, managerId });

  const show = await prisma.show.findUnique({
    where: { id: showId },
    include: { screen: true, bookedSeats: { take: 1 } },
  });
  if (!show) schedulingError('SHOW_NOT_FOUND', 'Show not found');

  if (show.bookedSeats.length > 0) {
    schedulingError('HAS_BOOKINGS', 'Cannot delete a show that has existing bookings');
  }

  if (managerRole !== 'ADMIN' && show.screen.managerId !== managerId) {
    schedulingError('NOT_YOUR_SCREEN', 'You are not the manager of this screen');
  }

  await prisma.show.delete({ where: { id: showId } });
  return { showId, deleted: true };
}

/** Check no overlap and ≥ 30-min gap between consecutive shows on this screen */
async function validateGapAndOverlap(
  screenId: string,
  startTime: Date,
  endTime: Date,
  excludeShowId: string | null
) {
  const gapMs = MIN_GAP_MINUTES * 60 * 1000;

  // Find any show whose window (with gap buffer) overlaps the proposed window
  const conflicts = await prisma.show.findMany({
    where: {
      screenId,
      ...(excludeShowId ? { id: { not: excludeShowId } } : {}),
      OR: [
        // Proposed show overlaps an existing show's window
        { startTime: { lt: endTime }, endTime: { gt: startTime } },
        // Proposed show is within 30 min of existing show's end
        {
          endTime: {
            gt: new Date(startTime.getTime() - gapMs),
            lte: startTime,
          },
        },
        // An existing show starts within 30 min of proposed show's end
        {
          startTime: {
            gte: endTime,
            lt: new Date(endTime.getTime() + gapMs),
          },
        },
      ],
    },
    take: 1,
  });

  if (conflicts.length > 0) {
    const conflict = conflicts[0]!;
    // Determine specific error
    if (
      conflict.startTime < endTime && conflict.endTime > startTime
    ) {
      schedulingError('OVERLAP', `This show overlaps with show ${conflict.id} on the same screen`);
    }
    schedulingError(
      'GAP_TOO_SHORT',
      `Shows must have at least ${MIN_GAP_MINUTES} minutes between them for cleaning`
    );
  }
}
