### Task 1: Backend API - Thread Endpoints

**Files:**
- Modify: `cinebook-server/src/agent/conversationService.ts`
- Modify: `cinebook-server/src/routes/agentRouter.ts`

**Interfaces:**
- Produces: `GET /api/agents/:agentId/threads` (returns `Conversation[]`)
- Produces: `GET /api/agents/:agentId/threads/:threadId` (returns `{ id, messages: Message[] }`)

- [ ] **Step 1: Add query functions to conversationService.ts**

Open `cinebook-server/src/agent/conversationService.ts` and add these two functions at the bottom:

```typescript
export async function getConversationsForUser(userId: string) {
  return prisma.conversation.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
}

export async function getConversationWithMessages(conversationId: string, userId: string) {
  return prisma.conversation.findFirst({
    where: { id: conversationId, userId },
    include: {
      messages: {
        orderBy: { createdAt: 'asc' },
      },
    },
  });
}
```

- [ ] **Step 2: Add API routes to agentRouter.ts**

Open `cinebook-server/src/routes/agentRouter.ts`. Add imports for the new functions and define the routes before the existing `/:agentId/run` route to avoid parameter conflicts.

```typescript
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
    const thread = await getConversationWithMessages(req.params.threadId, userId);
    if (!thread) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    res.json(thread);
  } catch (err) {
    next(err);
  }
});
```

- [ ] **Step 3: Commit backend changes**

```bash
git add cinebook-server/src/agent/conversationService.ts cinebook-server/src/routes/agentRouter.ts
git commit -m "feat(api): add thread history endpoints"
```

---

