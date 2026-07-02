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
