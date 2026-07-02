import 'package:flutter/foundation.dart';

@immutable
class ChatState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> bookingContext;
  final String? threadId;

  const ChatState({
    this.isLoading = false,
    this.error,
    this.bookingContext = const {},
    this.threadId,
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? bookingContext,
    String? threadId,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookingContext: bookingContext ?? this.bookingContext,
      threadId: threadId ?? this.threadId,
    );
  }
}
