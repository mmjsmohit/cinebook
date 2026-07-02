// src/routes/agentRouter.ts
import { Router } from 'express';
import { runAgent } from '../agent/orchestrator.js';
import { requireAuth } from '../middlewares/authMiddleware.js';

const router = Router();

/**
 * POST /api/agents/:agentId/run
 * Start a conversation with the CineBook AI agent.
 * The connection remains open and streams SSE events (AG-UI protocol) back to the client.
 */
router.post('/:agentId/run', requireAuth, async (req, res, next) => {
  try {
    // requireAuth guarantees req.user exists
    const userId = req.user!.id;
    const role = req.user!.role;
    const { threadId } = req.body;
    let message = req.body.message;
    if (req.body.messages && Array.isArray(req.body.messages) && req.body.messages.length > 0) {
      const lastMessage = req.body.messages[req.body.messages.length - 1];
      message = lastMessage.content;
    }

    if (!message || typeof message !== 'string') {
      res.status(400).json({ error: 'message or messages array with content is required' });
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
