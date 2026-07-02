import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiClient),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(tokenStorage: tokenStorage)..add(AuthStarted()),
        child: const CinebookApp(),
      ),
    ),
  );
}

class CinebookApp extends StatelessWidget {
  const CinebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineBook',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state is AuthAuthenticated) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
