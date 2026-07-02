import { Router } from 'express';
import { applyPromoCode } from '../services/promoService.js';
import { promoApplySchema } from '../schemas/index.js';

const router = Router();

// POST /promo/apply
router.post('/apply', async (req, res, next) => {
  try {
    const { code, amount } = promoApplySchema.parse(req.body);
    const result = await applyPromoCode(code, amount);
    if (!result.valid) {
      res.status(404).json({
        error: { code: 'PROMO_NOT_FOUND', message: 'Promo code not found or inactive' },
      });
      return;
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
