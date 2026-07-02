import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import type { TheatreQueryInput } from '../schemas/index.js';

export async function listTheatres(input: TheatreQueryInput) {
  logger.info('theatreService.listTheatres', { input });

  if (input.movieId) {
    // Which theatres have at least one show for this movie?
    const shows = await prisma.show.findMany({
      where: { movieId: input.movieId },
      select: { screen: { select: { theatreId: true, theatre: true } } },
      distinct: ['screenId'],
    });

    const theatreMap = new Map<string, typeof shows[number]['screen']['theatre']>();
    for (const s of shows) {
      const t = s.screen.theatre;
      if (!input.city || t.city.toLowerCase() === input.city.toLowerCase()) {
        theatreMap.set(t.id, t);
      }
    }
    return Array.from(theatreMap.values());
  }

  if (input.city) {
    return prisma.theatre.findMany({
      where: { city: { equals: input.city, mode: 'insensitive' } },
      orderBy: { name: 'asc' },
      include: { screens: true },
    });
  }

  return prisma.theatre.findMany({ 
    orderBy: { name: 'asc' },
    include: { screens: true },
  });
}

