## Task 1: Install dependencies + add schemas for agent tool inputs

**Files:**
- Modify: `cinebook-server/package.json`
- Modify: `cinebook-server/src/schemas/index.ts`
- Modify: `cinebook-server/.env`

**Interfaces:**
- Produces:
  - `agentRunSchema` — Zod schema for `POST /agent/run` body: `{ message: string, threadId?: string }`
  - All tool-specific input schemas exported from `src/schemas/index.ts`

- [ ] **Step 1: Install `ai@^7` and `@openrouter/ai-sdk-provider@^2.10`**

  ```bash
  cd /Users/mohittiwari/Dev/Cinebook/cinebook-server
  npm install ai@^7 @openrouter/ai-sdk-provider@^2.10
  ```

  Expected: `added N packages` with no peer-dependency errors. If you see a `specificationVersion` mismatch, run `npm install ai@latest @openrouter/ai-sdk-provider@latest` to align.

- [ ] **Step 2: Verify the installed versions are compatible**

  ```bash
  node --input-type=module <<< "import { streamText } from 'ai'; console.log('OK:', typeof streamText);"
  ```

  Expected: `OK: function`

- [ ] **Step 3: Add `OPENROUTER_API_KEY` to `.env`**

  Append to `cinebook-server/.env`:
  ```
  OPENROUTER_API_KEY=your_key_here
  ```

- [ ] **Step 4: Add agent-specific Zod schemas to `src/schemas/index.ts`**

  Append to the bottom of `src/schemas/index.ts`:

  ```typescript
  // ─── Agent / Chat Schemas ────────────────────────────────────────────────────

  export const agentRunSchema = z.object({
    message: z.string().min(1).max(4000),
    threadId: z.string().optional(),
  });

  export const delegateSchema = z.object({
    request: z.string(),
    userId: z.string(),
  });

  // Tool-specific input schemas (reused as tool inputSchema)

  export const getMovieDetailsSchema = z.object({ movieId: z.string() });
  export const getCastSchema = z.object({ movieId: z.string() });
  export const getReviewsSchema = z.object({ movieId: z.string() });
  export const suggestSimilarSchema = z.object({ movieId: z.string() });
  export const getScreenInfoSchema = z.object({ screenId: z.string() });
  export const checkSeatAvailabilitySchema = z.object({ showId: z.string() });

  export const holdSeatsToolSchema = z.object({
    showId: z.string(),
    seatIds: z.array(z.string()).min(1).max(10),
  });

  export const releaseSeatsToolSchema = z.object({
    showId: z.string(),
    seatIds: z.array(z.string()).min(1).max(10),
    holdToken: z.string(),
  });

  export const createBookingToolSchema = z.object({
    showId: z.string(),
    seatIds: z.array(z.string()).min(1).max(10),
    holdToken: z.string(),
    promoCode: z.string().optional(),
  });

  export const checkBookingStatusSchema = z.object({ bookingId: z.string() });
  export const cancelBookingToolSchema = z.object({ bookingId: z.string() });

  export const startPaymentToolSchema = z.object({
    bookingId: z.string(),
    cardNumber: z.string().min(4).max(19).default('4000'),
  });

  export const updatePreferencesSchema = z.object({
    prefs: z.record(z.unknown()),
  });

  export const contactSupportSchema = z.object({
    message: z.string(),
    category: z.enum(['booking', 'payment', 'general']).default('general'),
  });

  // Type exports
  export type AgentRunInput = z.infer<typeof agentRunSchema>;
  export type DelegateInput = z.infer<typeof delegateSchema>;
  ```

- [ ] **Step 5: Verify TypeScript compiles**

  ```bash
  cd /Users/mohittiwari/Dev/Cinebook/cinebook-server
  npx tsc --noEmit
  ```

  Expected: no errors.

- [ ] **Step 6: Commit**

  ```bash
  git add package.json package-lock.json src/schemas/index.ts .env
  git commit -m "feat(phase3): install ai sdk v7 + add agent input schemas"
  ```

---

