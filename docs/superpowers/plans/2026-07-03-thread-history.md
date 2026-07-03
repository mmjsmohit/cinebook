# Thread History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement API endpoints and Flutter UI to view and resume past AI chat threads.

**Architecture:** We will add two backend endpoints using Prisma to query `Conversation` and `Message` models. The Flutter app will use a side drawer in `AgentScreen` to list these threads, fetching them via `ApiClient`'s Dio instance. Tapping a thread dispatches a `ChatSwitchThread` event to the `ChatBloc`, which populates the chat history.

**Tech Stack:** Node.js, Express, Prisma, Flutter, flutter_bloc, Dio

## Global Constraints

- Follow existing formatting and architectural patterns.
- Do not modify the existing AG-UI streaming protocol.

---

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

### Task 2: Frontend State and Events

**Files:**
- Modify: `cinebook_user_app/lib/blocs/chat/chat_state.dart`
- Modify: `cinebook_user_app/lib/blocs/chat/chat_event.dart`
- Modify: `cinebook_user_app/lib/blocs/chat/chat_bloc.dart`

**Interfaces:**
- Consumes: `GET /api/agents/cinebook/threads` and `GET /api/agents/cinebook/threads/:threadId`
- Produces: `ChatState` with `threads` and `isLoadingThreads`, `ChatFetchThreads` and `ChatSwitchThread` events.

- [ ] **Step 1: Update ChatState**

Modify `cinebook_user_app/lib/blocs/chat/chat_state.dart` to add `threads` and `isLoadingThreads`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class ChatState {
  final bool isLoading;
  final bool isLoadingThreads;
  final String? error;
  final Map<String, dynamic> bookingContext;
  final String? threadId;
  final List<dynamic> threads;

  const ChatState({
    this.isLoading = false,
    this.isLoadingThreads = false,
    this.error,
    this.bookingContext = const {},
    this.threadId,
    this.threads = const [],
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isLoadingThreads,
    String? error,
    Map<String, dynamic>? bookingContext,
    String? threadId,
    List<dynamic>? threads,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingThreads: isLoadingThreads ?? this.isLoadingThreads,
      error: error,
      bookingContext: bookingContext ?? this.bookingContext,
      threadId: threadId ?? this.threadId,
      threads: threads ?? this.threads,
    );
  }
}
```

- [ ] **Step 2: Update ChatEvent**

Modify `cinebook_user_app/lib/blocs/chat/chat_event.dart` to add two new events:

```dart
class ChatFetchThreads extends ChatEvent {}

class ChatSwitchThread extends ChatEvent {
  final String threadId;
  const ChatSwitchThread(this.threadId);
}
```

- [ ] **Step 3: Implement event handlers in ChatBloc**

Modify `cinebook_user_app/lib/blocs/chat/chat_bloc.dart`:
Add imports if missing, register the events in the constructor, and add handler methods.

In constructor:
```dart
    on<ChatFetchThreads>(_onFetchThreads);
    on<ChatSwitchThread>(_onSwitchThread);
```

Add methods:
```dart
  Future<void> _onFetchThreads(ChatFetchThreads event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingThreads: true, error: null));
    try {
      final response = await apiClient.dio.get('/api/agents/cinebook/threads');
      emit(state.copyWith(isLoadingThreads: false, threads: response.data as List<dynamic>));
    } catch (e) {
      emit(state.copyWith(isLoadingThreads: false, error: 'Failed to fetch threads'));
    }
  }

  Future<void> _onSwitchThread(ChatSwitchThread event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await apiClient.dio.get('/api/agents/cinebook/threads/${event.threadId}');
      final data = response.data as Map<String, dynamic>;
      final messages = data['messages'] as List<dynamic>? ?? [];
      
      controller.clearMessages();
      
      final user = ChatUser(id: 'user');
      final aiUser = ChatUser(id: 'ai', firstName: 'CineBot');
      
      for (final msg in messages) {
        final role = msg['role'];
        final contentStr = msg['content'];
        // content is saved as JSON in prisma, might be a string or map depending on structure.
        // Assuming string content for standard messages:
        String textContent = '';
        if (contentStr is String) {
          textContent = contentStr;
        } else if (contentStr is Map) {
           // AG-UI or generic ai SDK message parsing:
           // Since we just streamText on backend, usually role is 'user' or 'model'
           // If there's an array of parts, we extract the text part.
           // For simplicity in this demo, let's grab 'text' or stringify.
           textContent = contentStr['text'] ?? contentStr.toString();
        }
        
        controller.addMessage(ChatMessage(
          user: role == 'user' ? user : aiUser,
          text: textContent,
          createdAt: DateTime.parse(msg['createdAt']),
        ));
      }
      
      emit(state.copyWith(isLoading: false, threadId: event.threadId));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load thread'));
    }
  }
```

- [ ] **Step 4: Commit state and bloc changes**

```bash
git add cinebook_user_app/lib/blocs/chat/
git commit -m "feat(app): add chat history state and events"
```

---

### Task 3: Frontend UI

**Files:**
- Modify: `cinebook_user_app/lib/screens/agent_screen.dart`

**Interfaces:**
- Consumes: `ChatState` (`threads`), `ChatFetchThreads`, `ChatSwitchThread`

- [ ] **Step 1: Update AgentScreen Build Method**

Wrap the `Column` inside a `Scaffold` with an `AppBar` and a `Drawer`. Dispatch `ChatFetchThreads` when the drawer opens or initially.

Modify `agent_screen.dart`:

```dart
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ChatBloc(apiClient: ctx.read<ApiClient>(), controller: _controller)..add(ChatFetchThreads()),
      child: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final bloc = context.read<ChatBloc>();

            return Scaffold(
              appBar: AppBar(
                title: const Text('CineBot'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                       bloc.add(ChatClearHistory());
                       // Reset threadId (requires adding to ClearHistory, or just clear UI)
                    },
                  )
                ],
              ),
              drawer: Drawer(
                child: SafeArea(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Past Threads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      if (state.isLoadingThreads)
                        const CircularProgressIndicator(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.threads.length,
                          itemBuilder: (context, index) {
                            final thread = state.threads[index];
                            return ListTile(
                              title: Text('Thread ${thread['id'].toString().substring(0, 8)}'),
                              subtitle: Text(thread['createdAt'].toString().substring(0, 10)),
                              onTap: () {
                                Navigator.pop(context); // close drawer
                                bloc.add(ChatSwitchThread(thread['id']));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: Column(
                children: [
                  if (state.bookingContext.containsKey('holdToken') || state.bookingContext.containsKey('heldSeatIds'))
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.amber.shade100,
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have seats on hold. Please confirm booking before the hold expires.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: AiChatWidget(
                      currentUser: _currentUser,
                      aiUser: _aiUser,
                      controller: _controller,
                      onSendMessage: (msg) => bloc.add(ChatSendMessage(msg.text)),
                      onCancelGenerating: () => bloc.add(ChatCancelMessage()),
                      loadingConfig: LoadingConfig(isLoading: state.isLoading),
                      enableMarkdownStreaming: true,
                      streamingWordByWord: true,
                      streamingDuration: const Duration(milliseconds: 30),
                      resultRenderers: {
                        'movieList': (ctx, data) => _buildMovieList(data),
                        'movieCard': (ctx, data) => _buildMovieCard(data),
                        'showtimes': (ctx, data) => _buildShowtimes(data),
                        'seatMap': (ctx, data) => _buildSeatMapPreview(data),
                        'bookingSummary': (ctx, data) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBookingSummary(data),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () =>
                                    _showConfirmationDialog(context, bloc, data),
                                child: const Text('Confirm Booking'),
                              ),
                            ],
                          );
                        },
                        'paymentResult': (ctx, data) => _buildPaymentResult(data),
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
```

- [ ] **Step 2: Update ChatClearHistory to clear threadId**
In `chat_bloc.dart`:
```dart
  void _onClearHistory(ChatClearHistory event, Emitter<ChatState> emit) {
    controller.clearMessages();
    emit(state.copyWith(threadId: null));
  }
```
*Note: Because `copyWith` currently doesn't allow setting `threadId` to null if it falls back to `this.threadId`, we need to adjust `copyWith` in `chat_state.dart` to support nullification (e.g. using a wrapper or just changing it) or just emit `const ChatState()`.* Let's stick with `emit(const ChatState())` which resets everything, including `threads`. Wait, we don't want to reset `threads`. So:
```dart
  void _onClearHistory(ChatClearHistory event, Emitter<ChatState> emit) {
    controller.clearMessages();
    emit(ChatState(threads: state.threads)); // Resets everything else but keeps threads
  }
```

- [ ] **Step 3: Commit UI changes**

```bash
git add cinebook_user_app/lib/screens/agent_screen.dart cinebook_user_app/lib/blocs/chat/chat_bloc.dart
git commit -m "feat(app): add side drawer for thread history"
```
