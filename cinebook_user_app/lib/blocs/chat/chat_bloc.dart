import 'dart:async';
import 'dart:convert';
import 'package:ag_ui/ag_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiClient apiClient;
  final ChatMessagesController controller;
  AgUiClient? _agUiClient;
  CancelToken? _cancelToken;

  ChatBloc({
    required this.apiClient,
    required this.controller,
  }) : super(const ChatState()) {
    on<ChatSendMessage>(_onSendMessage);
    on<ChatCancelMessage>(_onCancelMessage);
    on<ChatClearHistory>(_onClearHistory);
    on<ChatFetchThreads>(_onFetchThreads);
    on<ChatSwitchThread>(_onSwitchThread);
  }

  Future<AgUiClient> _getClient() async {
    if (_agUiClient != null) return _agUiClient!;
    final token = await apiClient.tokenStorage.getAccessToken();
    _agUiClient = AgUiClient(
      config: AgUiClientConfig(
        baseUrl: '${apiClient.baseUrl}/api',
        defaultHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
    return _agUiClient!;
  }

  Future<void> _onSendMessage(ChatSendMessage event, Emitter<ChatState> emit) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, error: null));
    _cancelToken = CancelToken();

    final user = ChatUser(id: 'user');
    final aiUser = ChatUser(id: 'ai', firstName: 'CineBot');

    // Add user message to UI
    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    controller.addMessage(ChatMessage(
      user: user,
      text: event.text,
      createdAt: DateTime.now(),
      customProperties: {'id': userMessageId},
    ));

    try {
      final client = await _getClient();
      final stream = client.runAgent(
        'agents/cinebook/run',
        SimpleRunAgentInput(
          threadId: state.threadId,
          messages: [
            UserMessage(
              id: userMessageId,
              content: event.text,
            ),
          ],
        ),
        cancelToken: _cancelToken,
      );

      await for (final uiEvent in stream) {
        if (_cancelToken?.isCancelled ?? false) break;
        
        if (uiEvent is RunStartedEvent) {
          emit(state.copyWith(isLoading: true, threadId: uiEvent.threadId));
        } else if (uiEvent is TextMessageContentEvent) {
          final messageId = uiEvent.messageId;
          if (!controller.messages.any((m) => m.customProperties?['id'] == messageId)) {
            controller.addStreamingMessage(ChatMessage(
              user: aiUser,
              text: '', 
              createdAt: DateTime.now(),
              customProperties: {'id': messageId},
            ));
          }
          final existing = controller.messages.firstWhere((m) => m.customProperties?['id'] == messageId);
          controller.updateMessage(existing.copyWith(text: existing.text + uiEvent.delta));
        } else if (uiEvent is ToolCallStartEvent) {
          controller.addMessage(ChatMessage.loading(
            user: aiUser,
            id: uiEvent.toolCallId,
            text: 'Loading ${uiEvent.toolCallName}...',
          ));
        } else if (uiEvent is ToolCallResultEvent) {
          // Parse the JSON content
          Map<String, dynamic> resultData = {};
          try {
            resultData = jsonDecode(uiEvent.content) as Map<String, dynamic>;
          } catch (_) {}
          
          final renderHint = resultData['renderHint'] as String? ?? 'text';
          
          // Replace loading message with rich message
          controller.updateMessage(ChatMessage.rich(
            id: uiEvent.toolCallId,
            user: aiUser,
            resultKind: renderHint,
            data: resultData,
            createdAt: DateTime.now(),
          ));
        } else if (uiEvent is StateSnapshotEvent) {
          emit(state.copyWith(bookingContext: uiEvent.snapshot));
        } else if (uiEvent is RunFinishedEvent) {
          emit(state.copyWith(isLoading: false));
          if (controller.currentlyStreamingMessageId != null) {
            controller.stopStreamingMessage(controller.currentlyStreamingMessageId!);
          }
        } else if (uiEvent is RunErrorEvent) {
          emit(state.copyWith(isLoading: false, error: uiEvent.message));
        }
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
      if (controller.currentlyStreamingMessageId != null) {
        controller.stopStreamingMessage(controller.currentlyStreamingMessageId!);
      }
    }
  }

  void _onCancelMessage(ChatCancelMessage event, Emitter<ChatState> emit) {
    _cancelToken?.cancel();
    if (controller.currentlyStreamingMessageId != null) {
      controller.stopStreamingMessage(controller.currentlyStreamingMessageId!);
    }
    emit(state.copyWith(isLoading: false));
  }

  void _onClearHistory(ChatClearHistory event, Emitter<ChatState> emit) {
    controller.clearMessages();
    emit(ChatState(threads: state.threads));
  }

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
        String textContent = '';
        if (contentStr is String) {
          textContent = contentStr;
        } else if (contentStr is Map) {
           textContent = contentStr['text']?.toString() ?? contentStr.toString();
        } else if (contentStr is List) {
           // Array of parts, let's just grab text if available
           try {
             textContent = contentStr.firstWhere((p) => p['type'] == 'text')['text']?.toString() ?? '';
           } catch (_) {}
        }
        
        if (textContent.isNotEmpty) {
          controller.addMessage(ChatMessage(
            user: role == 'user' ? user : aiUser,
            text: textContent,
            createdAt: DateTime.parse(msg['createdAt']),
            customProperties: {'id': msg['id']},
          ));
        }
      }
      
      emit(state.copyWith(isLoading: false, threadId: event.threadId));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load thread'));
    }
  }
}
