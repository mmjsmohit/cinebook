import { prisma } from '../db.js';
import { logger } from '../infra/logger.js';

export async function applyPromoCode(code: string, amount: number) {
  logger.info('promoService.applyPromoCode', { code, amount });
  const promo = await prisma.promoCode.findUnique({ where: { code } });
  if (!promo || !promo.active) {
    return { valid: false, discounted: amount, discount: 0 };
  }
  const discount = Math.round((amount * promo.percentOff) / 100);
  return { valid: true, discounted: amount - discount, discount, percentOff: promo.percentOff };
}
