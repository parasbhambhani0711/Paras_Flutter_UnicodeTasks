import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_theme.dart';
import 'core/setup.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  final deps = await AppSetup.init();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: deps.firestoreRepository),
        RepositoryProvider.value(value: deps.geminiRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: deps.authBloc),
          BlocProvider.value(value: deps.taskBloc),
          BlocProvider.value(value: deps.noteBloc),
          BlocProvider.value(value: deps.chatBloc),
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
