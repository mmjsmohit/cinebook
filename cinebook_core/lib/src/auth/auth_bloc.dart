import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/token_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final TokenStorage tokenStorage;

  AuthBloc({required this.tokenStorage}) : super(AuthInitial()) {
    on<AuthStarted>((event, emit) async {
      final token = await tokenStorage.getAccessToken();
      final role = await tokenStorage.getUserRole();
      if (token != null && role != null) {
        emit(AuthAuthenticated(role));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoggedIn>((event, emit) async {
      await tokenStorage.saveTokens(
        access: event.accessToken,
        refresh: event.refreshToken,
        role: event.role,
      );
      emit(AuthAuthenticated(event.role));
    });

    on<AuthLoggedOut>((event, emit) async {
      await tokenStorage.clear();
      emit(AuthUnauthenticated());
    });
  }
}
