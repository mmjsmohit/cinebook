# Thread History Design

## Overview
Give users the ability to access their past AI chat threads and resume conversations where they left off.

## Architecture & Data Flow
1. **User intent**: User opens the side drawer in the Agent tab.
2. **Data fetching**: The Flutter app calls `GET /api/agents/:agentId/threads`.
3. **Selection**: User taps a past thread.
4. **Resuming**: The app calls `GET /api/agents/:agentId/threads/:threadId`, retrieves the historical messages, populates the chat UI, and updates the active `threadId`. Future messages sent are appended to this existing thread.

## Backend Changes
- **Endpoints**: Add two new routes in `src/routes/agentRouter.ts`:
  - `GET /api/agents/:agentId/threads`: Returns a list of all `Conversation` records for the authenticated user, ordered by `createdAt` descending.
  - `GET /api/agents/:agentId/threads/:threadId`: Returns a specific `Conversation` and its associated `Message` records.
- **Service layer**: Implement these queries in `conversationService.ts` using Prisma.

## Frontend Changes
- **Agent Screen UI**: Wrap `AgentScreen` body in a `Scaffold`. Add an `AppBar` with a hamburger icon. Add a `Drawer` widget that displays the list of past threads (showing the date or a snippet).
- **ChatBloc**:
  - **State**: Add `threads` list and `isLoadingThreads` boolean.
  - **Events**: 
    - Add `FetchThreads` to load history. 
    - Add `SwitchThread` to fetch a specific thread's messages, clear the current messages in `ChatMessagesController`, inject the historical messages, and update the current `threadId`.
- **API Client**: Add methods to call the new `/threads` and `/threads/:threadId` backend endpoints.

## Scope & Constraints
- The side drawer ensures the chat UI retains maximum vertical space.
- Adding an `AppBar` to `AgentScreen` means it will have a local app bar even though it is a tab.
- This design is self-contained and focuses solely on resuming conversations without modifying the core AG-UI streaming protocol.
