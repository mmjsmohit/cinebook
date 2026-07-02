import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';
import { paymentCircuitBreaker } from '../infra/circuitBreaker.js';
import { v4 as uuidv4 } from 'uuid';

/**
 * Card prefixes for deterministic simulation:
 * - '4000' → always succeeds
 * - '4111' → always fails
 * - anything else → ~50% random fail
 */
function simulateGateway(cardNumber: string): Promise<{ success: boolean; error?: string }> {
  const prefix4 = cardNumber.slice(0, 4);
  return new Promise((resolve) => {
    const delay = 1000 + Math.random() * 2000; // 1-3s
    setTimeout(() => {
      if (prefix4 === '4000') {
        resolve({ success: true });
      } else if (prefix4 === '4111') {
        resolve({ success: false, error: 'Card declined by issuer' });
      } else {
        const ok = Math.random() >= 0.5;
        resolve(ok ? { success: true } : { success: false, error: 'Payment gateway error — please retry' });
      }
    }, delay);
  });
}

export async function initiatePayment(bookingId: string, cardNumber: string) {
  logger.info('paymentService.initiatePayment', { bookingId });

  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { payment: true },
  });
  if (!booking) throw Object.assign(new Error('Booking not found'), { code: 'NOT_FOUND' });
  if (booking.status === 'CANCELLED') {
    throw Object.assign(new Error('Cannot pay for a cancelled booking'), { code: 'BOOKING_CANCELLED' });
  }
  if (booking.payment?.status === 'SUCCESS') {
    throw Object.assign(new Error('Booking already paid'), { code: 'ALREADY_PAID' });
  }

  // Wrap gateway call in circuit breaker
  const gatewayResult = await paymentCircuitBreaker.call(() =>
    simulateGateway(cardNumber)
  );

  const transactionId = uuidv4();

  if (!gatewayResult.success) {
    // Create/update payment record as FAILED
    const existing = await prisma.payment.findUnique({ where: { bookingId } });
    if (existing) {
      await prisma.payment.update({ where: { bookingId }, data: { status: 'FAILED' } });
    } else {
      await prisma.payment.create({
        data: { bookingId, amount: booking.totalCost, status: 'FAILED', transactionId },
      });
    }
    logger.warn('paymentService.initiatePayment.failed', { bookingId, error: gatewayResult.error });
    throw Object.assign(new Error(gatewayResult.error ?? 'Payment failed'), {
      code: 'PAYMENT_FAILED',
      retryable: true,
    });
  }

  // Success
  const payment = await prisma.$transaction(async (tx) => {
    const p = await tx.payment.upsert({
      where: { bookingId },
      create: { bookingId, amount: booking.totalCost, status: 'SUCCESS', transactionId },
      update: { status: 'SUCCESS', transactionId },
    });
    await tx.booking.update({ where: { id: bookingId }, data: { status: 'CONFIRMED' } });
    return p;
  });

  logger.info('paymentService.initiatePayment.success', { bookingId, transactionId: payment.transactionId });
  return { paymentId: payment.id, transactionId: payment.transactionId, status: 'SUCCESS' };
}

export async function refundPayment(paymentId: string, actorId: string, role: string) {
  logger.info('paymentService.refundPayment', { paymentId, actorId });

  const payment = await prisma.payment.findUnique({
    where: { id: paymentId },
    include: { booking: true },
  });
  if (!payment) throw Object.assign(new Error('Payment not found'), { code: 'NOT_FOUND' });
  if (payment.booking.userId !== actorId && role !== 'ADMIN') {
    throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' });
  }
  if (payment.status !== 'SUCCESS') {
    throw Object.assign(new Error('Only successful payments can be refunded'), {
      code: 'INVALID_STATE',
    });
  }

  await prisma.payment.update({ where: { id: paymentId }, data: { status: 'REFUNDED' } });
  logger.info('paymentService.refundPayment.success', { paymentId });
  return { paymentId, status: 'REFUNDED' };
}
