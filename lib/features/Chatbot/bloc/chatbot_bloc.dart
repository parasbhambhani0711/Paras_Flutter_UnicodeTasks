import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/gemini_repository.dart';
import '../data/chat_message.dart';

part 'chatbot_event.dart';
part 'chatbot_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GeminiRepository _geminiRepository;

  ChatBloc(this._geminiRepository)
      : super(ChatStateData(messages: [
          ChatMessage(
              text:
                  "Hello! I am your Study Brahmastra AI Tutor. How can I help you study today?",
              isUser: false)
        ])) {
    on<SendMessageEvent>((event, emit) async {
      final currentMessages =
          List<ChatMessage>.from((state as ChatStateData).messages);
      currentMessages.add(ChatMessage(text: event.text, isUser: true));

      emit(ChatStateData(messages: currentMessages, isLoading: true));

      try {
        final responseText = await _geminiRepository.getAiResponse(event.text);
        currentMessages.add(ChatMessage(text: responseText, isUser: false));
        emit(ChatStateData(messages: currentMessages, isLoading: false));
      } catch (e) {
        emit(ChatStateData(
          messages: currentMessages,
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
