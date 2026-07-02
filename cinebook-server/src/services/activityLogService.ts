import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import { Prisma } from '@prisma/client';

export async function logActivity(
  actorId: string,
  action: string,
  entity: string,
  metadata?: Record<string, unknown>
) {
  logger.info('activityLogService.logActivity', { actorId, action, entity });
  return prisma.adminActivityLog.create({
    data: {
      actorId,
      action,
      entity,
      metadata: (metadata ?? Prisma.JsonNull) as Prisma.InputJsonValue,
    },
  });
}

export async function getRecentActivity(limit = 50) {
  return prisma.adminActivityLog.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit,
  });
}
