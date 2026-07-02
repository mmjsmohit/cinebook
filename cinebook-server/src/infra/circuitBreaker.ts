import { redisClient } from '../redis.js';
import { logger } from './logger.js';

/**
 * Redis-backed Circuit Breaker for the payment service.
 *
 * States: CLOSED → OPEN (after N consecutive failures) → HALF_OPEN (cooldown) → CLOSED
 *
 * All state is in Redis so it's shared across multiple server instances.
 */

export interface CircuitBreakerOptions {
  name: string;
  /** Number of consecutive failures before opening the circuit */
  failureThreshold: number;
  /** Milliseconds to keep the circuit OPEN before probing (HALF_OPEN) */
  cooldownMs: number;
}

type CircuitState = 'CLOSED' | 'OPEN' | 'HALF_OPEN';

export class CircuitBreaker {
  private readonly name: string;
  private readonly failureThreshold: number;
  private readonly cooldownMs: number;

  constructor(opts: CircuitBreakerOptions) {
    this.name = opts.name;
    this.failureThreshold = opts.failureThreshold;
    this.cooldownMs = opts.cooldownMs;
  }

  private key(suffix: string) {
    return `cb:${this.name}:${suffix}`;
  }

  private async getState(): Promise<CircuitState> {
    const state = await redisClient.get(this.key('state'));
    if (!state) return 'CLOSED';
    return state as CircuitState;
  }

  private async setOpen() {
    // Store OPEN + set when it should become HALF_OPEN
    await redisClient.set(this.key('state'), 'OPEN');
    await redisClient.set(
      this.key('openedAt'),
      String(Date.now()),
      { EX: Math.ceil(this.cooldownMs / 1000) + 10 }
    );
    await redisClient.set(this.key('failures'), '0'); // reset counter
    logger.warn('Circuit breaker opened', { name: this.name });
  }

  private async setClosed() {
    await redisClient.set(this.key('state'), 'CLOSED');
    await redisClient.set(this.key('failures'), '0');
    await redisClient.del(this.key('openedAt'));
    logger.info('Circuit breaker closed', { name: this.name });
  }

  private async incrementFailures(): Promise<number> {
    const failures = await redisClient.incr(this.key('failures'));
    await redisClient.expire(this.key('failures'), Math.ceil(this.cooldownMs / 1000) + 60);
    return failures;
  }

  /**
   * Wraps an async operation with circuit-breaker protection.
   * Throws an error with code CIRCUIT_OPEN when the circuit is OPEN.
   */
  async call<T>(fn: () => Promise<T>): Promise<T> {
    const state = await this.getState();

    if (state === 'OPEN') {
      // Check if cooldown has expired — if so, allow one HALF_OPEN probe
      const openedAtStr = await redisClient.get(this.key('openedAt'));
      const openedAt = openedAtStr ? Number(openedAtStr) : 0;
      const elapsed = Date.now() - openedAt;

      if (elapsed < this.cooldownMs) {
        const err = new Error('Payments temporarily unavailable. Please try again shortly.');
        (err as any).code = 'CIRCUIT_OPEN';
        throw err;
      }

      // Transition to HALF_OPEN: allow probe
      await redisClient.set(this.key('state'), 'HALF_OPEN');
      logger.info('Circuit breaker half-open — probing', { name: this.name });
    }

    try {
      const result = await fn();
      // On success, close the circuit
      await this.setClosed();
      return result;
    } catch (err: unknown) {
      if ((err as any)?.code === 'CIRCUIT_OPEN') throw err;

      const failures = await this.incrementFailures();
      logger.warn('Circuit breaker recorded failure', { name: this.name, failures });

      if (failures >= this.failureThreshold) {
        await this.setOpen();
      }
      throw err;
    }
  }
}

/** Singleton circuit breaker for the payment gateway */
export const paymentCircuitBreaker = new CircuitBreaker({
  name: 'payment',
  failureThreshold: 5,
  cooldownMs: 30_000, // 30 s
});
