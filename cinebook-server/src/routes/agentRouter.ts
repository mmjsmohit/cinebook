// src/routes/agentRouter.ts
import { Router } from 'express';
import { runAgent } from '../agent/orchestrator.js';
import { requireAuth } from '../middlewares/authMiddleware.js';
import { getConversationsForUser, getConversationWithMessages } from '../agent/conversationService.js';

const router = Router();

router.get('/:agentId/threads', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user!.id;
    const threads = await getConversationsForUser(userId);
    res.json(threads);
  } catch (err) {
    next(err);
  }
});

router.get('/:agentId/threads/:threadId', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user!.id;
    const threadId = req.params.threadId as string;
    const thread = await getConversationWithMessages(threadId, userId);
    if (!thread) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    res.json(thread);
  } catch (err) {
    next(err);
  }
});

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
