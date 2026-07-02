import { redisClient } from '../redis.js';
import { logger } from '../infra/logger.js';
import { v4 as uuidv4 } from 'uuid';

const HOLD_TTL_MS = 300_000; // 5 minutes

/** Lua: only delete if value matches */
const COMPARE_AND_DELETE_SCRIPT = `
if redis.call('get', KEYS[1]) == ARGV[1] then
  return redis.call('del', KEYS[1])
else
  return 0
end
`;

function seatKey(showId: string, seatId: string) {
  return `seat:${showId}:${seatId}`;
}

/**
 * Hold up to N seats atomically.
 * Returns { holdToken, expiresAt } on success.
 * Returns { failedSeatIds } if any seat was already held/booked.
 */
export async function holdSeats(
  showId: string,
  seatIds: string[],
  userId: string
): Promise<{ holdToken: string; expiresAt: string } | { failedSeatIds: string[] }> {
  logger.info('holdService.holdSeats', { showId, seatIds, userId });

  const nonce = uuidv4();
  const ownerToken = `${userId}:${nonce}`;
  const grabbedSeatIds: string[] = [];
  const failedSeatIds: string[] = [];

  for (const seatId of seatIds) {
    const key = seatKey(showId, seatId);
    // SET key value NX PX 300000
    const result = await redisClient.set(key, ownerToken, { NX: true, PX: HOLD_TTL_MS });
    if (result === null) {
      failedSeatIds.push(seatId);
    } else {
      grabbedSeatIds.push(seatId);
    }
  }

  if (failedSeatIds.length > 0) {
    // Release anything we grabbed in this attempt
    await releaseByOwnerToken(showId, grabbedSeatIds, ownerToken);
    return { failedSeatIds };
  }

  const expiresAt = new Date(Date.now() + HOLD_TTL_MS).toISOString();
  return { holdToken: nonce, expiresAt };
}

/** Get the owner token for a held seat */
export async function getSeatOwnerToken(
  showId: string,
  seatId: string
): Promise<string | null> {
  return redisClient.get(seatKey(showId, seatId));
}

/** Release specific seats belonging to this ownerToken using compare-and-delete Lua */
export async function releaseByOwnerToken(
  showId: string,
  seatIds: string[],
  ownerToken: string
): Promise<void> {
  logger.info('holdService.releaseByOwnerToken', { showId, seatIds });
  await Promise.all(
    seatIds.map((seatId) =>
      (redisClient as unknown as {
        eval: (script: string, opts: { keys: string[]; arguments: string[] }) => Promise<number>;
      }).eval(COMPARE_AND_DELETE_SCRIPT, {
        keys: [seatKey(showId, seatId)],
        arguments: [ownerToken],
      })
    )
  );
}

/** Release all seats for a given holdToken (used after booking confirmation) */
export async function releaseHold(
  showId: string,
  seatIds: string[],
  userId: string,
  holdToken: string
): Promise<void> {
  const ownerToken = `${userId}:${holdToken}`;
  await releaseByOwnerToken(showId, seatIds, ownerToken);
}

/** Get the current Redis hold state for a list of seats */
export async function getHeldSeatIds(showId: string, seatIds: string[]): Promise<Set<string>> {
  const held = new Set<string>();
  const keys = seatIds.map((id) => seatKey(showId, id));
  if (keys.length === 0) return held;
  const values = await redisClient.mGet(keys);
  for (let i = 0; i < seatIds.length; i++) {
    if (values[i] !== null && values[i] !== undefined) {
      held.add(seatIds[i]!);
    }
  }
  return held;
}
