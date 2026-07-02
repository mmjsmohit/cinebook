import 'package:flutter/foundation.dart';

@immutable
abstract class ChatEvent {}

class ChatSendMessage extends ChatEvent {
  final String text;
  ChatSendMessage(this.text);
}

class ChatCancelMessage extends ChatEvent {}

class ChatClearHistory extends ChatEvent {}

class ChatFetchThreads extends ChatEvent {}

class ChatSwitchThread extends ChatEvent {
  final String threadId;
  const ChatSwitchThread(this.threadId);
}
