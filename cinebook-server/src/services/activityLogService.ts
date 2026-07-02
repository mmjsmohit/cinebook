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

export async function getActivityLog(filters: {
  actorId?: string;
  from?: string;
  to?: string;
  limit?: number;
}) {
  const where: Prisma.AdminActivityLogWhereInput = {};
  if (filters.actorId) where.actorId = filters.actorId;
  if (filters.from || filters.to) {
    where.createdAt = {
      ...(filters.from ? { gte: new Date(filters.from) } : {}),
      ...(filters.to ? { lte: new Date(filters.to) } : {}),
    };
  }
  return prisma.adminActivityLog.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: filters.limit ?? 100,
  });
}
