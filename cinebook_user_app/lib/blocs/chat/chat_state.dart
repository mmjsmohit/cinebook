import 'package:flutter/foundation.dart';

@immutable
class ChatState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> bookingContext;

  const ChatState({
    this.isLoading = false,
    this.error,
    this.bookingContext = const {},
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? bookingContext,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookingContext: bookingContext ?? this.bookingContext,
    );
  }
}
