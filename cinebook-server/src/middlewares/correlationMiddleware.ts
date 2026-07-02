import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { als } from '../infra/logger.js';

export function correlationMiddleware(): ReturnType<typeof Router> {
  const router = Router();
  router.use((req, res, next) => {
    const correlationId =
      (req.headers['x-correlation-id'] as string | undefined) || uuidv4();
    res.setHeader('x-correlation-id', correlationId);
    als.run({ correlationId }, () => next());
  });
  return router;
}
