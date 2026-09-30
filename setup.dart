// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final files = {
    'lib/core/theme/app_theme.dart': '''
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color brandRed = Color(0xFFDC2626);
  static const Color backgroundIvory = Color(0xFFFAFAF7);
  static const Color cardSurface = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundIvory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandRed,
        primary: primaryNavy,
        secondary: brandRed,
        surface: cardSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: brandRed),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryNavy,
        selectedItemColor: brandRed,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
''',
    'lib/core/api/gemini_repository.dart': '''
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiRepository {
  final String apiKey = "AQ.Ab8RN6Ia2VFdoaGlvrUX54t8MK4MuKilUfqv-pMYR9JcInjowQ";

  final List<String> _fallbackModels = [
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
  ];

  Future<String> getAiResponse(String prompt) async {
    String lastError = '';

    for (final model in _fallbackModels) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/\$model:generateContent?key=\$apiKey');

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          if (attempt > 0) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
          }

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text":
                          "You are Study Brahmastra AI, a helpful tutor for students. Be concise, clear, and encouraging. User question: \$prompt"
                    }
                  ]
                }
              ]
            }),
          );

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          }

          final jsonResponse = jsonDecode(response.body);
          lastError = jsonResponse['error']?['message'] ?? response.body;

          if (response.statusCode == 503 || response.statusCode == 429) {
            break;
          } else {
            throw Exception("Gemini Error (\${response.statusCode}): \$lastError");
          }
        } catch (e) {
          if (attempt == 1) rethrow;
        }
      }
    }

    throw Exception("All servers busy right now. Please try in 5 seconds. (\$lastError)");
  }
}
''',
    'lib/features/to-do/data/todo_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String subject;
  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    this.isCompleted = false,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? 'General',
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
''',
    'lib/features/Notes/data/note_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NoteModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
''',
    'lib/core/data/firestore_repository.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/to-do/data/todo_model.dart';
import '../../features/Notes/data/note_model.dart';

class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- Dynamic Subjects ---
  Stream<List<String>> getSubjectsStream() {
    if (_uid == null) return Stream.value(['General']);
    return _db
        .collection('Users')
        .doc(_uid)
        .collection('subjects')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return ['General'];
      }
      final list = snap.docs.map((doc) => doc['name'] as String).toList();
      if (!list.contains('General')) list.insert(0, 'General');
      return list;
    });
  }

  Future<void> addSubject(String name) async {
    if (_uid == null) return;
    await _db
        .collection('Users')
        .doc(_uid)
        .collection('subjects')
        .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
  }

  // --- Tasks ---
  Stream<List<TaskModel>> getTasksStream() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('Users')
        .doc(_uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Future<void> addTask(String title, String subject) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('tasks').add({
      'title': title,
      'subject': subject,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTask(String taskId, bool currentStatus) async {
    if (_uid == null) return;
    await _db
        .collection('Users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});
  }

  Future<void> deleteTask(String taskId) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('tasks').doc(taskId).delete();
  }

  // --- Notes ---
  Stream<List<NoteModel>> getNotesStream() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('Users')
        .doc(_uid)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NoteModel.fromFirestore(doc)).toList());
  }

  Future<void> addNote(String title, String content) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('notes').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('notes').doc(noteId).delete();
  }
}
''',
    'lib/features/Chatbot/data/chat_message.dart': '''
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}
''',
    'lib/features/Login/bloc/auth_bloc.dart': '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthEvent>((event, emit) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });

    on<LogoutEvent>((event, emit) async {
      await FirebaseAuth.instance.signOut();
      emit(Unauthenticated());
    });
  }
}
''',
    'lib/features/Login/bloc/auth_event.dart': '''
part of 'auth_bloc.dart';

abstract class AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}
''',
    'lib/features/Login/bloc/auth_state.dart': '''
part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}
''',
    'lib/features/to-do/bloc/todo_bloc.dart': '''
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/firestore_repository.dart';
import '../data/todo_model.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FirestoreRepository _repository;
  StreamSubscription? _subscription;

  TaskBloc(this._repository) : super(TaskLoading()) {
    on<LoadTasksEvent>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository.getTasksStream().listen(
            (tasks) => add(_TasksUpdatedEvent(tasks)),
            onError: (err) => emit(TaskError(err.toString())),
          );
    });

    on<_TasksUpdatedEvent>((event, emit) => emit(TaskLoaded(event.tasks)));

    on<AddTaskEvent>((event, emit) async {
      await _repository.addTask(event.title, event.subject);
    });

    on<ToggleTaskEvent>((event, emit) async {
      await _repository.toggleTask(event.taskId, event.currentStatus);
    });

    on<DeleteTaskEvent>((event, emit) async {
      await _repository.deleteTask(event.taskId);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
''',
    'lib/features/to-do/bloc/todo_event.dart': '''
part of 'todo_bloc.dart';

abstract class TaskEvent {}

class LoadTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final String title;
  final String subject;
  AddTaskEvent(this.title, this.subject);
}

class ToggleTaskEvent extends TaskEvent {
  final String taskId;
  final bool currentStatus;
  ToggleTaskEvent(this.taskId, this.currentStatus);
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  DeleteTaskEvent(this.taskId);
}

class _TasksUpdatedEvent extends TaskEvent {
  final List<TaskModel> tasks;
  _TasksUpdatedEvent(this.tasks);
}
''',
    'lib/features/to-do/bloc/todo_state.dart': '''
part of 'todo_bloc.dart';

abstract class TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  TaskLoaded(this.tasks);
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}
''',
    'lib/features/Notes/bloc/notes_bloc.dart': '''
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/firestore_repository.dart';
import '../data/note_model.dart';

part 'notes_event.dart';
part 'notes_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final FirestoreRepository _repository;
  StreamSubscription? _subscription;

  NoteBloc(this._repository) : super(NoteLoading()) {
    on<LoadNotesEvent>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository.getNotesStream().listen(
            (notes) => add(_NotesUpdatedEvent(notes)),
            onError: (err) => emit(NoteError(err.toString())),
          );
    });

    on<_NotesUpdatedEvent>((event, emit) => emit(NoteLoaded(event.notes)));

    on<AddNoteEvent>((event, emit) async {
      await _repository.addNote(event.title, event.content);
    });

    on<DeleteNoteEvent>((event, emit) async {
      await _repository.deleteNote(event.noteId);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
''',
    'lib/features/Notes/bloc/notes_event.dart': '''
part of 'notes_bloc.dart';

abstract class NoteEvent {}

class LoadNotesEvent extends NoteEvent {}

class AddNoteEvent extends NoteEvent {
  final String title;
  final String content;
  AddNoteEvent(this.title, this.content);
}

class DeleteNoteEvent extends NoteEvent {
  final String noteId;
  DeleteNoteEvent(this.noteId);
}

class _NotesUpdatedEvent extends NoteEvent {
  final List<NoteModel> notes;
  _NotesUpdatedEvent(this.notes);
}
''',
    'lib/features/Notes/bloc/notes_state.dart': '''
part of 'notes_bloc.dart';

abstract class NoteState {}

class NoteLoading extends NoteState {}

class NoteLoaded extends NoteState {
  final List<NoteModel> notes;
  NoteLoaded(this.notes);
}

class NoteError extends NoteState {
  final String message;
  NoteError(this.message);
}
''',
    'lib/features/Chatbot/bloc/chatbot_bloc.dart': '''
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
''',
    'lib/features/Chatbot/bloc/chatbot_event.dart': '''
part of 'chatbot_bloc.dart';

abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String text;
  SendMessageEvent(this.text);
}
''',
    'lib/features/Chatbot/bloc/chatbot_state.dart': '''
part of 'chatbot_bloc.dart';

abstract class ChatState {}

class ChatStateData extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatStateData({required this.messages, this.isLoading = false, this.error});
}
''',
    'lib/features/Splash Screen/splash_screen.dart': '''
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';
import '../Home/view/main_layout_screen.dart';
import '../Login/view/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainLayoutScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/splash_animation.json',
              width: 250,
              height: 250,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/icon.png', width: 120),
            ),
            const SizedBox(height: 24),
            const Text(
              'STUDY BRAHMASTRA',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                  letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
''',
    'lib/features/Login/view/login_screen.dart': '''
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../Home/view/main_layout_screen.dart';
import '../../Signin/view/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/icon.png',
                  height: 90,
                  errorBuilder: (_, __, ___) => const Icon(Icons.school,
                      size: 80, color: AppTheme.brandRed)),
              const SizedBox(height: 16),
              const Text('Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy)),
              const SizedBox(height: 32),
              TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                                  email: _email.text.trim(),
                                  password: _pass.text.trim());
                          if (!mounted) return;
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MainLayoutScreen()));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login Failed: \$e')));
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Log In'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: const Text("Don't have an account? Sign Up",
                    style: TextStyle(color: AppTheme.primaryNavy)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
''',
    'lib/features/Signin/view/signup_screen.dart': '''
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../Home/view/main_layout_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Join Study Brahmastra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy)),
              const SizedBox(height: 32),
              TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        try {
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                  email: _email.text.trim(),
                                  password: _pass.text.trim());
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MainLayoutScreen()),
                              (r) => false);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Signup Failed: \$e')));
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''',
    'lib/features/Home/view/home_tab.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/firestore_repository.dart';
import '../../to-do/bloc/todo_bloc.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PageController carouselController = PageController();
    final List<String> studyTips = [
      "Pomodoro Technique: Study 25 mins, rest 5 mins.",
      "Active Recall: Test yourself frequently while revising.",
      "Spaced Repetition: Review notes after 1, 3, and 7 days.",
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, \${FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student'}!',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppTheme.primaryNavy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.format_quote,
                        color: AppTheme.brandRed, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '"Arise, awake, and stop not till the goal is reached."',
                        style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Study Tips Carousel',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: PageView.builder(
                controller: carouselController,
                itemCount: studyTips.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: AppTheme.brandRed),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(studyTips[index],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your Subjects',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy)),
            const SizedBox(height: 8),
            StreamBuilder<List<String>>(
              stream: context.read<FirestoreRepository>().getSubjectsStream(),
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? ['General'];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  itemCount: subjects.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == subjects.length) {
                      return InkWell(
                        onTap: () => _showAddSubjectDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          color: Colors.red.shade50,
                          elevation: 1,
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle,
                                    color: AppTheme.brandRed),
                                SizedBox(width: 6),
                                Text('Add Subject',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryNavy)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Card(
                      elevation: 2,
                      child: Center(
                        child: ListTile(
                          leading:
                              const Icon(Icons.book, color: AppTheme.brandRed),
                          title: Text(subjects[idx],
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Upcoming Tasks',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy)),
            const SizedBox(height: 8),
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoaded) {
                  final pending =
                      state.tasks.where((t) => !t.isCompleted).toList();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions,
                          color: AppTheme.brandRed),
                      title: Text('\${pending.length} Pending Tasks'),
                      subtitle: Text(pending.isNotEmpty
                          ? 'Next: \${pending.first.title}'
                          : 'No pending tasks!'),
                    ),
                  );
                }
                return const Card(
                    child: ListTile(title: Text('Loading tasks...')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Subject'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Computer Networks')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<FirestoreRepository>()
                    .addSubject(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Subject'),
          )
        ],
      ),
    );
  }
}
''',
    'lib/features/to-do/view/tasks_tab.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/firestore_repository.dart';
import '../bloc/todo_bloc.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  bool _showCompleted = false;
  final Set<String> _fadingTaskIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showCompleted ? 'Showing All Tasks' : 'Showing Active Tasks',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showCompleted = !_showCompleted),
                  icon: Icon(
                    _showCompleted
                        ? Icons.visibility_off
                        : Icons.check_circle_outline,
                    color: AppTheme.brandRed,
                  ),
                  label: Text(
                    _showCompleted ? 'Hide Completed' : 'Show Completed',
                    style: const TextStyle(color: AppTheme.primaryNavy),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TaskError) {
                  return Center(child: Text('Error: \${state.message}'));
                }
                if (state is TaskLoaded) {
                  final displayTasks = _showCompleted
                      ? state.tasks
                      : state.tasks.where((t) => !t.isCompleted).toList();

                  if (displayTasks.isEmpty) {
                    return Center(
                      child: Text(
                        _showCompleted
                            ? 'No tasks created yet!'
                            : 'All caught up! Tap + to add a task.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: displayTasks.length,
                    itemBuilder: (context, index) {
                      final task = displayTasks[index];
                      final isFading = _fadingTaskIds.contains(task.id);
                      final isDone = task.isCompleted || isFading;

                      return Dismissible(
                        key: Key(task.id),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          context
                              .read<TaskBloc>()
                              .add(DeleteTaskEvent(task.id));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Task "\${task.title}" deleted')));
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity:
                              isFading ? 0.0 : (task.isCompleted ? 0.35 : 1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isDone ? Colors.grey.shade100 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isDone
                                  ? []
                                  : const [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 4)
                                    ],
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: AppTheme.brandRed,
                                checkColor: Colors.white,
                                value: isDone,
                                onChanged: (_) async {
                                  if (!task.isCompleted) {
                                    setState(() {
                                      _fadingTaskIds.add(task.id);
                                    });

                                    await Future.delayed(
                                        const Duration(milliseconds: 500));

                                    if (mounted) {
                                      context.read<TaskBloc>().add(
                                          ToggleTaskEvent(
                                              task.id, task.isCompleted));
                                      setState(() {
                                        _fadingTaskIds.remove(task.id);
                                      });
                                    }
                                  } else {
                                    context.read<TaskBloc>().add(
                                        ToggleTaskEvent(
                                            task.id, task.isCompleted));
                                  }
                                },
                              ),
                              title: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: AppTheme.brandRed,
                                  decorationThickness: 2.0,
                                  color: isDone
                                      ? Colors.grey.shade600
                                      : AppTheme.primaryNavy,
                                  fontWeight: isDone
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  fontSize: 16,
                                ),
                                child: Text(task.title),
                              ),
                              subtitle: Text(task.subject,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Study Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<String>>(
              stream: context.read<FirestoreRepository>().getSubjectsStream(),
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? ['General'];
                selectedSubject ??= subjects.first;

                return DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Select Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (val) => selectedSubject = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                context.read<TaskBloc>().add(AddTaskEvent(
                      titleCtrl.text.trim(),
                      selectedSubject ?? 'General',
                    ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Task'),
          )
        ],
      ),
    );
  }
}
''',
    'lib/features/Notes/view/notes_tab.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/notes_bloc.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NoteBloc, NoteState>(
        builder: (context, state) {
          if (state is NoteLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NoteLoaded) {
            if (state.notes.isEmpty) {
              return const Center(
                  child: Text('No notes yet. Tap + to create one!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(note.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy)),
                    subtitle: Text(note.content,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => context
                          .read<NoteBloc>()
                          .add(DeleteNoteEvent(note.id)),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.note_add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                context.read<NoteBloc>().add(AddNoteEvent(
                    titleCtrl.text.trim(), contentCtrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Note'),
          )
        ],
      ),
    );
  }
}
''',
    'lib/features/Chatbot/view/chatbot_page.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/chatbot_bloc.dart';

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatStateData) {
            _scrollToBottom();
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
            }
          }
        },
        builder: (context, state) {
          final chatData = state as ChatStateData;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatData.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatData.messages[index];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? AppTheme.primaryNavy
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                              color: msg.isUser
                                  ? Colors.white
                                  : AppTheme.primaryNavy),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (chatData.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.brandRed)),
                      SizedBox(width: 10),
                      Text('AI Tutor is thinking...'),
                    ],
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                            hintText: 'Ask your study doubt...',
                            border: InputBorder.none),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.brandRed),
                      onPressed: () {
                        if (_msgController.text.trim().isNotEmpty) {
                          context.read<ChatBloc>().add(
                              SendMessageEvent(_msgController.text.trim()));
                          _msgController.clear();
                        }
                      },
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
''',
    'lib/features/Profile/view/profile_tab.dart': '''
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../Login/view/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryNavy,
              child: Icon(Icons.person, size: 60, color: AppTheme.brandRed),
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? 'student@brahmastra.com',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: AppTheme.primaryNavy),
                title: const Text('Email ID'),
                subtitle: Text(user?.email ?? 'N/A'),
              ),
            ),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.verified, color: AppTheme.primaryNavy),
                title: const Text('Status'),
                subtitle: Text(user != null ? 'Active Member' : 'Guest'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label:
                  const Text('Log Out', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
''',
    'lib/features/Home/view/main_layout_screen.dart': '''
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../Login/view/login_screen.dart';
import 'home_tab.dart';
import '../../to-do/view/tasks_tab.dart';
import '../../Notes/view/notes_tab.dart';
import '../../Chatbot/view/chatbot_page.dart';
import '../../Profile/view/profile_tab.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    TasksTab(),
    NotesTab(),
    AiChatTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png',
                height: 28,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.auto_stories, color: AppTheme.brandRed)),
            const SizedBox(width: 10),
            const Text('Study Brahmastra'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryNavy,
              ),
              accountName: const Text('Study Brahmastra User',
                  style: TextStyle(
                      color: AppTheme.brandRed, fontWeight: FontWeight.bold)),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ??
                  'student@brahmastra.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppTheme.brandRed,
                child: Icon(Icons.person, color: Colors.white, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppTheme.primaryNavy),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryNavy),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.primaryNavy),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false);
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
''',
    'lib/main.dart': '''
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/data/firestore_repository.dart';
import 'core/api/gemini_repository.dart';

import 'features/Splash Screen/splash_screen.dart';
import 'features/Login/bloc/auth_bloc.dart';
import 'features/to-do/bloc/todo_bloc.dart';
import 'features/Notes/bloc/notes_bloc.dart';
import 'features/Chatbot/bloc/chatbot_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestoreRepository = FirestoreRepository();
  final geminiRepository = GeminiRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: firestoreRepository),
        RepositoryProvider.value(value: geminiRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc()..add(CheckAuthEvent())),
          BlocProvider(
              create: (_) =>
                  TaskBloc(firestoreRepository)..add(LoadTasksEvent())),
          BlocProvider(
              create: (_) =>
                  NoteBloc(firestoreRepository)..add(LoadNotesEvent())),
          BlocProvider(create: (_) => ChatBloc(geminiRepository)),
        ],
        child: const StudyBrahmastraApp(),
      ),
    ),
  );
}

class StudyBrahmastraApp extends StatelessWidget {
  const StudyBrahmastraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Brahmastra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
''',
  };

  for (var entry in files.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
    print('Created: \${entry.key}');
  }
  print('\nSUCCESS! Segregated directory structure generated!');
}
