// src/agent/tools/profileTools.ts
import { tool } from 'ai';
import { z } from 'zod';
import { updatePreferencesSchema, contactSupportSchema } from '../../schemas/index.js';
import { prisma } from '../../db.js';
import { searchMovies } from '../../services/movieService.js';
import { withToolLogger } from '../toolLogger.js';

/**
 * Factory that creates the 4 profile/support tools bound to the authenticated userId.
 */
export function createProfileTools(userId: string) {
  return {
    getProfile: tool({
      description:
        "Get the current user's profile including name, phone, and preferences. Use when user asks 'what are my preferences' or 'show my profile'.",
      inputSchema: z.object({}),
      execute: withToolLogger('getProfile', async () => {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: { id: true, name: true, phone: true, prefs: true, role: true, createdAt: true },
        });
        if (!user) throw new Error('User not found');
        return JSON.parse(JSON.stringify({ renderHint: 'text' as const, user }));
      }),
    }),

    updatePreferences: tool({
      description:
        "Update the user's preferences (preferred language, seat category, favourite genres). Use when user says 'I prefer Hindi movies' or 'set my preferred seat to RECLINER'.",
      inputSchema: updatePreferencesSchema,
      execute: withToolLogger('updatePreferences', async ({ prefs }) => {
        const updated = await prisma.user.update({
          where: { id: userId },
          data: { prefs: prefs as object },
          select: { id: true, prefs: true },
        });
        return JSON.parse(JSON.stringify({ renderHint: 'text' as const, updated: true, prefs: updated.prefs }));
      }),
    }),

    getRecommendations: tool({
      description:
        "Get personalised movie recommendations based on user preferences (preferred genre, language). Use when user asks 'recommend something for me' or 'what should I watch?'.",
      inputSchema: z.object({}),
      execute: withToolLogger('getRecommendations', async () => {
        const user = await prisma.user.findUnique({ where: { id: userId }, select: { prefs: true } });
        const prefs = (user?.prefs as Record<string, unknown>) ?? {};
        const genre = typeof prefs.genre === 'string' ? prefs.genre : undefined;
        const language = typeof prefs.language === 'string' ? prefs.language : undefined;
        const movies = await searchMovies({ genre, language });
        return JSON.parse(JSON.stringify({ renderHint: 'movieList' as const, movies: movies.slice(0, 10) }));
      }),
    }),

    contactSupport: tool({
      description:
        "Log a support message from the user. Use when user reports an issue or needs human support. Category: 'booking', 'payment', or 'general'.",
      inputSchema: contactSupportSchema,
      execute: withToolLogger('contactSupport', async ({ message, category }) => {
        await prisma.adminActivityLog.create({
          data: {
            actorId: userId,
            action: 'SUPPORT_REQUEST',
            entity: category,
            metadata: { message },
          },
        });
        return {
          renderHint: 'text' as const,
          acknowledged: true,
          message: 'Your support request has been logged. Our team will follow up shortly.',
        };
      }),
    }),

    requestPreferencesForm: tool({
      description:
        "Show an interactive preferences form to collect user booking filters (date, time, party size, seat category). Use this tool when the user wants to set search preferences, search parameters, or asks to fill in details.",
      inputSchema: z.object({}),
      execute: withToolLogger('requestPreferencesForm', async () => {
        return {
          renderHint: 'a2ui' as const,
          surfaceId: 'booking-preferences-form',
          components: [
            {
              type: 'form',
              id: 'pref_form',
              children: [
                {
                  type: 'datePicker',
                  id: 'date',
                  label: 'Show Date',
                  required: true,
                },
                {
                  type: 'timePicker',
                  id: 'time',
                  label: 'Preferred Time of Day',
                  required: true,
                },
                {
                  type: 'counter',
                  id: 'partySize',
                  label: 'Number of Tickets (Party Size)',
                  min: 1,
                  max: 10,
                  defaultValue: 2,
                },
                {
                  type: 'dropdown',
                  id: 'seatCategory',
                  label: 'Preferred Seating Category',
                  options: ['NORMAL', 'PREMIUM', 'RECLINER'],
                  defaultValue: 'NORMAL',
                },
              ],
            },
          ],
        };
      }),
    }),
  };
}
