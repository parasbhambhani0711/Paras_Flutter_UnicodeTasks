import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/repositories/firestore_repository.dart';
import '../data/repositories/gemini_repository.dart';
import '../logic/auth/auth_bloc.dart';
import '../logic/task/task_bloc.dart';
import '../logic/note/note_bloc.dart';
import '../logic/chat/chat_bloc.dart';
import 'services/notification_service.dart';
import '../../firebase_options.dart';

class AppDependencies {
  final FirestoreRepository firestoreRepository;
  final GeminiRepository geminiRepository;
  final AuthBloc authBloc;
  final TaskBloc taskBloc;
  final NoteBloc noteBloc;
  final ChatBloc chatBloc;

  AppDependencies({
    required this.firestoreRepository,
    required this.geminiRepository,
    required this.authBloc,
    required this.taskBloc,
    required this.noteBloc,
    required this.chatBloc,
  });
}

class AppSetup {
  static Future<AppDependencies> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("dotenv load warning: $e");
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase init warning: $e");
    }

    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint("NotificationService init warning: $e");
    }

    final firestoreRepository = FirestoreRepository();
    final geminiRepository = GeminiRepository();

    final authBloc = AuthBloc()..add(CheckAuthEvent());
    final taskBloc = TaskBloc(firestoreRepository);
    final noteBloc = NoteBloc(firestoreRepository);
    final chatBloc = ChatBloc(
      geminiRepository: geminiRepository,
      firestoreRepository: firestoreRepository,
      taskBloc: taskBloc,
      noteBloc: noteBloc,
    );

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        taskBloc.add(LoadTasksEvent());
        noteBloc.add(LoadNotesEvent());
      }
    });

    return AppDependencies(
      firestoreRepository: firestoreRepository,
      geminiRepository: geminiRepository,
      authBloc: authBloc,
      taskBloc: taskBloc,
      noteBloc: noteBloc,
      chatBloc: chatBloc,
    );
  }
}
