# Phase 4 — Flutter AI UI (user app)

**Stack:** `ag_ui` (0.3.0), `flutter_gen_ai_chat_ui` (2.14.0), Bloc.
**Purpose:** Add the chatbot to the customer app — consume the Phase 3 AG-UI SSE stream and render streaming text plus rich tool-result widgets.

**Tightly tied to:**
- **Consumes Phase 3** — connects to `POST /agent/run` and depends on the AG-UI event contract + the `renderHint` enum defined in `Phase-3-AI-Backend.md §8`.
- **Extends the Phase 2 user app** — drops into the tab slot left ready there. Reuses its `dio`/auth stack for the token.

---

## 1. Packages & roles

- **`ag_ui`** — `AgUiClient` opens the SSE connection and yields typed events (`TextMessageContentEvent`, `ToolCallStartEvent`, `ToolCallResultEvent`, `StateSnapshotEvent`/`StateDeltaEvent`, `RunFinishedEvent`). It's a young community SDK — pin `^0.3.0` and wrap it behind your own interface so a breaking bump is contained.
- **`flutter_gen_ai_chat_ui`** — `AiChatWidget` + `ChatMessagesController` for the chat surface: word-by-word streaming, markdown, `ChatMessage.rich()`/`ChatMessage.loading()` for inline widgets.

> Use this package's **streaming + rich-widget** features. Do **not** use its `AiActionProvider` for execution — that assumes *client-side* tools, but your tools run server-side (Phase 3). The one piece worth borrowing is its human-in-the-loop confirmation dialog (§7).

---

## 2. ChatBloc — the translation layer

`ChatBloc` owns the `AgUiClient` stream and maps AG-UI events → `ChatMessagesController` calls.

```dart
final client = AgUiClient(config: AgUiClientConfig(
  baseUrl: apiBase,
  defaultHeaders: {'Authorization': 'Bearer $accessToken'},
));

await for (final event in client.runAgent('cinebook', input, cancelToken: _cancel)) {
  mapEventToController(event); // §3
}
```

Keep the `renderHint` → widget mapping (§6) in the Bloc/registry, not scattered in the UI.

---

## 3. Event → UI mapping

| AG-UI event | UI action |
|---|---|
| `RunStartedEvent` | set `loadingConfig.isLoading = true` |
| `TextMessageContentEvent` | stream into a bubble (§4) |
| `ToolCallStartEvent` | insert `ChatMessage.loading()` shimmer ("checking seats…") |
| `ToolCallResultEvent` | replace shimmer with `ChatMessage.rich()` widget per `renderHint` (§6) |
| `StateSnapshotEvent` / `StateDeltaEvent` | apply to a client booking-context store (JSON-Patch) → drives running total / held-seats banner |
| `RunFinishedEvent` | `isLoading = false`; finalize |
| `RunErrorEvent` | error bubble + retry affordance |

---

## 4. Streaming text bubble

`flutter_gen_ai_chat_ui`'s streaming: push an **empty** `ChatMessage` with a **stable id**, then `updateMessage` with the *same id* on every `TextMessageContentEvent.delta`. Flags — both required:

```dart
AiChatWidget(
  controller: controller,
  currentUser: me, aiUser: ai,
  onSendMessage: _send,               // -> ChatBloc.add(SendMessage)
  enableMarkdownStreaming: true,      // master gate
  streamingWordByWord: true,          // word vs char
  streamingDuration: const Duration(milliseconds: 30),
  onCancelGenerating: _cancel,        // §8
);
```

---

## 5. Send path

`onSendMessage` → `ChatBloc.add(SendMessage(text))` → opens/continues the `AgUiClient.runAgent` stream against `/agent/run` with the current `threadId`. The stream's events flow back through §3. One in-flight run at a time.

---

## 6. Rich tool-result widgets (the payoff)

Register a builder per `renderHint` (contract from Phase 3 §8). On `ToolCallResultEvent`, render the payload as a native widget instead of JSON:

| `renderHint` | Widget |
|---|---|
| `movieList` | horizontal movie cards (tap → detail) |
| `movieCard` | poster + meta + "book" CTA |
| `showtimes` | date/time chips grouped by theatre |
| `seatMap` | compact seat grid (reuses Phase 2's seat widget, read-only preview) |
| `bookingSummary` | seats + total + hold countdown |
| `paymentResult` | success/fail state |
| `text` (fallback) | plain markdown bubble |

This is what makes the doc's weekend-sci-fi scenario feel like "talking to a helpful person, not filling out a form."

---

## 7. Human-in-the-loop confirmation

Before the agent finalizes book/pay, gate it with a confirmation dialog (borrow `flutter_gen_ai_chat_ui`'s built-in confirmation UX). The user's choice is sent back as the next message to `/agent/run`, and the orchestrator continues. Execution still happens server-side — the client only confirms intent.

---

## 8. Cancellation

`onCancelGenerating` → `_cancel.cancel()` on the `AgUiClient` `CancelToken` **and** `controller.stopStreamingMessage(id)` to finalize the partial bubble.

> Caveat from Phase 3 §1: OpenRouter mid-stream cancel is provider-dependent — with Anthropic/OpenAI the model actually stops; with some providers it keeps generating server-side. The UI stops either way.

---

## 9. Appendix — A2UI stretch (~3–4 h, only if everything else lands)

A2UI is Google's declarative generative-UI protocol (stable **v0.9.1**), transport-agnostic and able to ride your existing AG-UI stream. Flutter renders it via the **GenUI SDK** — **both are alpha/experimental and expected to churn**, so keep this contained.

**Time-boxed scope:** one **agent-generated preferences form** — date picker + time-of-day + party size + seat category. The agent emits an A2UI JSON payload; the client renders it from a **catalog of trusted Flutter widgets** (the catalog is the security boundary — the agent can only compose from it, never send code). On submit, fire a named event back to `/agent/run`.

If it fights you, cut it — §6's rich widgets already cover the core UX. Do **not** make anything load-bearing depend on A2UI.

---

## 10. Definition of done

- [ ] Chat streams token-by-token from `/agent/run`.
- [ ] Tool calls show a shimmer, then resolve into the correct rich widget per `renderHint`.
- [ ] Booking context (held seats, running total) stays in sync via state events.
- [ ] Book/pay is gated by a confirmation dialog.
- [ ] Stop button cancels cleanly and finalizes the partial message.
- [ ] Full conversational booking works end-to-end inside the customer app.

---

## 11. Reference documentation

- `ag_ui` (Dart SDK) — https://pub.dev/packages/ag_ui
- `ag_ui` API reference — https://pub.dev/documentation/ag_ui/latest/
- AG-UI — Dart client overview — https://docs.ag-ui.com/sdk/dart/client/overview
- AG-UI — concepts/architecture — https://docs.ag-ui.com/concepts/architecture
- `flutter_gen_ai_chat_ui` — https://pub.dev/packages/flutter_gen_ai_chat_ui
- `flutter_gen_ai_chat_ui` — GitHub — https://github.com/hooshyar/flutter_gen_ai_chat_ui
- A2UI — home / spec — https://a2ui.org/
- A2UI — intro (Google) — https://developers.googleblog.com/introducing-a2ui-an-open-project-for-agent-driven-interfaces/
- A2UI v0.9 (over AG-UI) — https://developers.googleblog.com/a2ui-v0-9-generative-ui/
- A2UI — GitHub — https://github.com/google/A2UI
- Flutter GenUI + A2UI (overview) — https://stackademic.com/blog/generative-ui-in-flutter-genui-and-the-a2ui-protocol
- A2UI composer (prototype widgets) — https://a2ui-editor.ag-ui.com/
- Phase 3 event + `renderHint` contract — `Phase-3-AI-Backend.md`
