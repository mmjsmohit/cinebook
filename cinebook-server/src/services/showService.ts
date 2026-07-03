import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import type { Prisma } from '@prisma/client';
import type { ShowQueryInput } from '../schemas/index.js';

export async function getShows(input: ShowQueryInput) {
  logger.info('showService.getShows', { input });

  const where: Prisma.ShowWhereInput = {};

  if (input.movieId) where.movieId = input.movieId;
  if (input.format) where.format = input.format;

  if (input.date) {
    const day = new Date(input.date);
    const nextDay = new Date(day);
    nextDay.setDate(nextDay.getDate() + 1);
    
    const now = new Date();
    where.startTime = { 
      gte: now > day ? now : day, 
      lt: nextDay 
    };
  }

  if (input.city || input.screenType) {
    where.screen = {
      ...(input.city
        ? { theatre: { city: { equals: input.city, mode: 'insensitive' } } }
        : {}),
      ...(input.screenType ? { type: input.screenType } : {}),
    };
  }

  return prisma.show.findMany({
    where,
    include: {
      movie: { select: { id: true, title: true, posterUrl: true, runtimeMin: true } },
      screen: { include: { theatre: true } },
    },
    orderBy: { startTime: 'asc' },
    take: 100,
  });
}

export async function getShowById(id: string) {
  logger.info('showService.getShowById', { id });
  return prisma.show.findUnique({
    where: { id },
    include: {
      movie: true,
      screen: { include: { theatre: true, seats: { orderBy: [{ row: 'asc' }, { number: 'asc' }] } } },
    },
  });
}
