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
