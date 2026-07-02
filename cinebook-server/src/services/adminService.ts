import { prisma } from '../db.js';
import type { Prisma } from '@prisma/client';
import { logger } from '../infra/logger.js';
import { logActivity } from './activityLogService.js';
import { createShow } from './scheduleService.js';
import type {
  AdminUserPatchInput,
  AdminUserRoleInput,
  AdminMovieCreateInput,
  AdminMoviePatchInput,
  AdminTheatreCreateInput,
  AdminTheatrePatchInput,
  AdminScreenCreateInput,
  AdminScreenPatchInput,
  AdminShowCreateInput,
  AdminReportsQueryInput,
} from '../schemas/index.js';

// ─── Users ───────────────────────────────────────────────────────────────────

export async function listUsers() {
  logger.info('adminService.listUsers');
  return prisma.user.findMany({
    select: { id: true, phone: true, name: true, role: true, disabled: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
  });
}

export async function patchUser(actorId: string, userId: string, data: AdminUserPatchInput) {
  logger.info('adminService.patchUser', { actorId, userId });
  const updateData = Object.fromEntries(Object.entries(data).filter(([_, v]) => v !== undefined));
  const user = await prisma.user.update({
    where: { id: userId },
    data: updateData,
    select: { id: true, phone: true, name: true, role: true, disabled: true },
  });
  await logActivity(actorId, 'UPDATE_USER', `User:${userId}`, data);
  return user;
}

export async function disableUser(actorId: string, userId: string) {
  logger.info('adminService.disableUser', { actorId, userId });
  const user = await prisma.user.update({
    where: { id: userId },
    data: { disabled: true },
    select: { id: true, phone: true, name: true, role: true, disabled: true },
  });
  await logActivity(actorId, 'DISABLE_USER', `User:${userId}`);
  return user;
}

export async function assignRole(actorId: string, userId: string, data: AdminUserRoleInput) {
  logger.info('adminService.assignRole', { actorId, userId, role: data.role });
  const user = await prisma.user.update({
    where: { id: userId },
    data: { role: data.role },
    select: { id: true, phone: true, name: true, role: true, disabled: true },
  });
  await logActivity(actorId, 'ASSIGN_ROLE', `User:${userId}`, { role: data.role });
  return user;
}

// ─── Movies ──────────────────────────────────────────────────────────────────

export async function createMovie(actorId: string, data: AdminMovieCreateInput) {
  logger.info('adminService.createMovie', { actorId, title: data.title });
  const { genreIds, ...movieData } = data;
  const createData: Prisma.MovieCreateInput = {
    ...movieData,
    posterUrl: movieData.posterUrl ?? null,
    trailerUrl: movieData.trailerUrl ?? null,
    releaseDate: new Date(movieData.releaseDate),
  };
  if (genreIds.length > 0) {
    createData.genres = { connect: genreIds.map((id) => ({ id })) };
  }
  const movie = await prisma.movie.create({
    data: createData,
    include: { genres: true },
  });
  await logActivity(actorId, 'CREATE_MOVIE', `Movie:${movie.id}`, { title: data.title });
  return movie;
}

export async function patchMovie(actorId: string, movieId: string, data: AdminMoviePatchInput) {
  logger.info('adminService.patchMovie', { actorId, movieId });
  const { genreIds, ...movieData } = data;
  const updateData: Record<string, unknown> = { ...movieData };
  if (movieData.releaseDate) updateData.releaseDate = new Date(movieData.releaseDate);
  if (genreIds !== undefined) {
    updateData.genres = { set: genreIds.map((id) => ({ id })) };
  }
  const movie = await prisma.movie.update({
    where: { id: movieId },
    data: updateData,
    include: { genres: true },
  });
  await logActivity(actorId, 'UPDATE_MOVIE', `Movie:${movieId}`, data);
  return movie;
}

// ─── Theatres ────────────────────────────────────────────────────────────────

export async function createTheatre(actorId: string, data: AdminTheatreCreateInput) {
  logger.info('adminService.createTheatre', { actorId, name: data.name });
  const theatre = await prisma.theatre.create({ data });
  await logActivity(actorId, 'CREATE_THEATRE', `Theatre:${theatre.id}`, { name: data.name });
  return theatre;
}

export async function patchTheatre(actorId: string, theatreId: string, data: AdminTheatrePatchInput) {
  logger.info('adminService.patchTheatre', { actorId, theatreId });
  const updateData = Object.fromEntries(Object.entries(data).filter(([_, v]) => v !== undefined));
  const theatre = await prisma.theatre.update({ where: { id: theatreId }, data: updateData });
  await logActivity(actorId, 'UPDATE_THEATRE', `Theatre:${theatreId}`, data);
  return theatre;
}

// ─── Screens ─────────────────────────────────────────────────────────────────

export async function createScreen(actorId: string, data: AdminScreenCreateInput) {
  logger.info('adminService.createScreen', { actorId, name: data.name });
  const { seats, ...screenData } = data;
  const screen = await prisma.screen.create({
    data: {
      ...screenData,
      managerId: screenData.managerId ?? null,
      ...(seats && seats.length > 0 ? { seats: { create: seats } } : {}),
    },
    include: { theatre: true, seats: true },
  });
  await logActivity(actorId, 'CREATE_SCREEN', `Screen:${screen.id}`, { name: data.name, theatreId: data.theatreId });
  return screen;
}

export async function patchScreen(actorId: string, screenId: string, data: AdminScreenPatchInput) {
  logger.info('adminService.patchScreen', { actorId, screenId });
  const { seats, ...screenData } = data;

  const updateData = Object.fromEntries(Object.entries(screenData).filter(([_, v]) => v !== undefined));
  const screen = await prisma.$transaction(async (tx) => {
    const updated = await tx.screen.update({
      where: { id: screenId },
      data: updateData,
    });
    // If seats are provided, replace entire seat layout
    if (seats) {
      await tx.seat.deleteMany({ where: { screenId } });
      if (seats.length > 0) {
        await tx.seat.createMany({
          data: seats.map((s) => ({ ...s, screenId })),
        });
      }
    }
    return tx.screen.findUnique({
      where: { id: screenId },
      include: { theatre: true, seats: true },
    });
  });

  await logActivity(actorId, 'UPDATE_SCREEN', `Screen:${screenId}`, data);
  return screen;
}

// ─── Shows (admin override — bypasses ownership check) ───────────────────────

export async function createAdminShow(actorId: string, data: AdminShowCreateInput) {
  logger.info('adminService.createAdminShow', { actorId, screenId: data.screenId });
  // Reuse scheduleService.createShow with ADMIN role to bypass ownership
  const show = await createShow(
    data.screenId,
    actorId,
    'ADMIN',
    {
      movieId: data.movieId,
      startTime: data.startTime,
      basePrice: data.basePrice,
      language: data.language,
      format: data.format,
    }
  );
  await logActivity(actorId, 'OVERRIDE_CREATE_SHOW', `Show:${show.id}`, {
    screenId: data.screenId,
    movieId: data.movieId,
  });
  return show;
}

// ─── Reports ─────────────────────────────────────────────────────────────────

export async function getReports(input: AdminReportsQueryInput) {
  logger.info('adminService.getReports', { range: input.range });

  const now = new Date();
  let since: Date;
  let groupByFormat: 'day' | 'week' | 'month';

  switch (input.range) {
    case 'daily':
      since = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000); // last 30 days
      groupByFormat = 'day';
      break;
    case 'weekly':
      since = new Date(now.getTime() - 12 * 7 * 24 * 60 * 60 * 1000); // last 12 weeks
      groupByFormat = 'week';
      break;
    case 'monthly':
      since = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000); // last 12 months
      groupByFormat = 'month';
      break;
  }

  // Server-side aggregation
  const bookings = await prisma.booking.findMany({
    where: {
      createdAt: { gte: since },
      status: { in: ['CONFIRMED', 'PENDING'] },
    },
    select: {
      createdAt: true,
      totalCost: true,
    },
    orderBy: { createdAt: 'asc' },
  });

  // Bucket bookings by period
  const buckets = new Map<string, { count: number; revenue: number }>();
  for (const b of bookings) {
    const d = b.createdAt;
    let key: string;
    if (groupByFormat === 'day') {
      key = d.toISOString().slice(0, 10); // YYYY-MM-DD
    } else if (groupByFormat === 'week') {
      // ISO week start (Monday)
      const day = d.getDay();
      const diff = d.getDate() - day + (day === 0 ? -6 : 1);
      const monday = new Date(d);
      monday.setDate(diff);
      key = monday.toISOString().slice(0, 10);
    } else {
      key = d.toISOString().slice(0, 7); // YYYY-MM
    }
    const existing = buckets.get(key) ?? { count: 0, revenue: 0 };
    existing.count++;
    existing.revenue += b.totalCost;
    buckets.set(key, existing);
  }

  const data = Array.from(buckets.entries())
    .map(([period, stats]) => ({ period, ...stats }))
    .sort((a, b) => a.period.localeCompare(b.period));

  const totalBookings = data.reduce((sum, d) => sum + d.count, 0);
  const totalRevenue = data.reduce((sum, d) => sum + d.revenue, 0);

  return { range: input.range, totalBookings, totalRevenue, data };
}
