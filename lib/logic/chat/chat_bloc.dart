import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/task_model.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/firestore_repository.dart';
import '../../data/repositories/gemini_repository.dart';
import '../task/task_bloc.dart';
import '../note/note_bloc.dart';

abstract class ChatEvent {}
class SendMessageEvent extends ChatEvent {
  final String text;
  final String? imagePath;
  final String? base64Image;

  SendMessageEvent(this.text, {this.imagePath, this.base64Image});
}

abstract class ChatState {}
class ChatStateData extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatStateData({required this.messages, this.isLoading = false, this.error});
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GeminiRepository _geminiRepository;
  final FirestoreRepository _firestoreRepository;
  final TaskBloc _taskBloc;
  final NoteBloc _noteBloc;

  ChatBloc({
    required GeminiRepository geminiRepository,
    required FirestoreRepository firestoreRepository,
    required TaskBloc taskBloc,
    required NoteBloc noteBloc,
  })  : _geminiRepository = geminiRepository,
        _firestoreRepository = firestoreRepository,
        _taskBloc = taskBloc,
        _noteBloc = noteBloc,
        super(ChatStateData(messages: [
          ChatMessage(
              text:
                  "Hello! I am **Study Brahmastra AI**, your study agent. I can help you answer doubts, manage tasks, edit subjects/notes, and organize your studies!",
              isUser: false)
        ])) {
    on<SendMessageEvent>((event, emit) async {
      final currentMessages =
          List<ChatMessage>.from((state as ChatStateData).messages);
      currentMessages.add(ChatMessage(
        text: event.text,
        isUser: true,
        imagePath: event.imagePath,
        base64Image: event.base64Image,
      ));

      emit(ChatStateData(messages: currentMessages, isLoading: true));

      List<TaskModel> activeTasks = [];
      if (_taskBloc.state is TaskLoaded) {
        activeTasks = (_taskBloc.state as TaskLoaded).rawTasks;
      }

      List<NoteModel> activeNotes = [];
      if (_noteBloc.state is NoteLoaded) {
        activeNotes = (_noteBloc.state as NoteLoaded).rawNotes;
      }

      final String appContextSummary = '''
CURRENT APP STATE SNAPSHOT:
- Existing Subjects: ${_firestoreRepository.cachedSubjects.join(', ')}
- Tasks (${activeTasks.length} total):
${activeTasks.isEmpty ? '  (No tasks created yet)' : activeTasks.map((t) => '  * "${t.title}" | Subject: ${t.subject} | Status:${t.isCompleted ? "Completed" : "Pending"}').join('\n')}
- Notes (${activeNotes.length} total):${activeNotes.isEmpty ? '  (No notes created yet)' : activeNotes.map((n) => '  * "${n.title}": "${n.content}"').join('\n')}
''';

      try {
        final responseText = await _geminiRepository.getAiResponse(
            currentMessages, appContextSummary);

        try {
          String cleanedText = responseText.trim();
          if (cleanedText.startsWith('```json')) {
            cleanedText = cleanedText.substring(7);
          } else if (cleanedText.startsWith('```')) {
            cleanedText = cleanedText.substring(3);
          }
          if (cleanedText.endsWith('```')) {
            cleanedText = cleanedText.substring(0, cleanedText.length - 3);
          }
          cleanedText = cleanedText.trim();

          final Map<String, dynamic> aiJson = jsonDecode(cleanedText);
          final action = aiJson['action'];
          final reply = aiJson['reply'] ?? 'Action completed!';

          if (action == 'ADD_TASK') {
            final title = aiJson['title'] ?? 'New Task';
            final subject = aiJson['subject'] ?? 'General';
            _taskBloc.add(AddTaskEvent(title, subject));
          } else if (action == 'TOGGLE_TASK') {
            final target = (aiJson['title'] ?? '').toString().toLowerCase();
            final match = activeTasks.firstWhere(
              (t) =>
                  t.title.toLowerCase().contains(target) ||
                  target.contains(t.title.toLowerCase()),
              orElse: () => TaskModel(id: '', title: '', subject: ''),
            );
            if (match.id.isNotEmpty) {
              _taskBloc.add(ToggleTaskEvent(match.id, match.isCompleted));
            }
          } else if (action == 'DELETE_TASK') {
            final target = (aiJson['title'] ?? '').toString().toLowerCase();
            final match = activeTasks.firstWhere(
              (t) =>
                  t.title.toLowerCase().contains(target) ||
                  target.contains(t.title.toLowerCase()),
              orElse: () => TaskModel(id: '', title: '', subject: ''),
            );
            if (match.id.isNotEmpty) {
              _taskBloc.add(DeleteTaskEvent(match.id));
            }
          } else if (action == 'ADD_SUBJECT') {
            final subject = aiJson['subject'] ?? 'General';
            _firestoreRepository.addSubject(subject);
          } else if (action == 'RENAME_SUBJECT') {
            final oldSub = aiJson['oldSubject'] ?? '';
            final newSub = aiJson['newSubject'] ?? '';
            _firestoreRepository.renameSubject(oldSub, newSub);
          } else if (action == 'DELETE_SUBJECT') {
            final subject = aiJson['subject'] ?? '';
            _firestoreRepository.deleteSubject(subject);
          } else if (action == 'ADD_NOTE') {
            final title = aiJson['title'] ?? 'New Note';
            final content = aiJson['content'] ?? '';
            _noteBloc.add(AddNoteEvent(title, content));
          } else if (action == 'EDIT_NOTE' || action == 'RENAME_NOTE') {
            final target = (aiJson['oldTitle'] ?? '').toString().toLowerCase();
            final newTitle = aiJson['newTitle'] ?? aiJson['title'] ?? '';
            final newContent = aiJson['newContent'] ?? aiJson['content'] ?? '';
            final match = activeNotes.firstWhere(
              (n) =>
                  n.title.toLowerCase().contains(target) ||
                  target.contains(n.title.toLowerCase()),
              orElse: () => NoteModel(
                  id: '', title: '', content: '', createdAt: DateTime.now()),
            );
            if (match.id.isNotEmpty) {
              final finalTitle = newTitle.isNotEmpty ? newTitle : match.title;
              final finalContent =
                  newContent.isNotEmpty ? newContent : match.content;
              _firestoreRepository.updateNote(
                  match.id, finalTitle, finalContent);
            }
          } else if (action == 'DELETE_NOTE') {
            final target = (aiJson['title'] ?? '').toString().toLowerCase();
            final match = activeNotes.firstWhere(
              (n) =>
                  n.title.toLowerCase().contains(target) ||
                  target.contains(n.title.toLowerCase()),
              orElse: () => NoteModel(
                  id: '', title: '', content: '', createdAt: DateTime.now()),
            );
            if (match.id.isNotEmpty) {
              _noteBloc.add(DeleteNoteEvent(match.id));
            }
          }

          currentMessages.add(ChatMessage(text: reply, isUser: false));
        } catch (_) {
          currentMessages.add(ChatMessage(text: responseText, isUser: false));
        }

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
