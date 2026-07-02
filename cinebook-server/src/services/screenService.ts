import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';

export async function getScreenById(id: string) {
  logger.info('screenService.getScreenById', { id });
  return prisma.screen.findUnique({
    where: { id },
    include: {
      theatre: true,
      seats: { orderBy: [{ row: 'asc' }, { number: 'asc' }] },
      manager: { select: { id: true, name: true, phone: true } },
    },
  });
}

export async function getScreensForManager(managerId: string) {
  logger.info('screenService.getScreensForManager', { managerId });
  return prisma.screen.findMany({
    where: { managerId },
    include: { theatre: true },
    orderBy: { name: 'asc' },
  });
}
