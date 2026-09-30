part of 'chatbot_bloc.dart';

abstract class ChatState {}

class ChatStateData extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatStateData({required this.messages, this.isLoading = false, this.error});
}
