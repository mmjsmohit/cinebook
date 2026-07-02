// src/routes/agentRouter.ts
import { Router } from 'express';
import { runAgent } from '../agent/orchestrator.js';
import { requireAuth } from '../middlewares/authMiddleware.js';

const router = Router();

/**
 * POST /api/agent
 * Start a conversation with the CineBook AI agent.
 * The connection remains open and streams SSE events (AG-UI protocol) back to the client.
 */
router.post('/', requireAuth, async (req, res, next) => {
  try {
    // requireAuth guarantees req.user exists
    const userId = req.user!.id;
    const role = req.user!.role;
    const { message, threadId } = req.body;

    if (!message || typeof message !== 'string') {
      res.status(400).json({ error: 'message is required and must be a string' });
      return;
    }

    // runAgent handles the SSE response internally, including res.end()
    await runAgent({
      userId,
      role,
      message,
      threadId,
      res,
    });
  } catch (error) {
    next(error);
  }
});

export default router;
