import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'screens/login_screen.dart';
import 'screens/screens_list_screen.dart';

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
        child: const CinebookHallApp(),
      ),
    ),
  );
}

class CinebookHallApp extends StatelessWidget {
  const CinebookHallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineBook Hall Manager',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state is AuthAuthenticated) {
            if (state.role != 'HALL_MANAGER' && state.role != 'SUPER_ADMIN') {
              return const _UnauthorizedScreen();
            }
            return const ScreensListScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Unauthorized. Manager access required.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AuthBloc>().add(AuthLoggedOut()),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
