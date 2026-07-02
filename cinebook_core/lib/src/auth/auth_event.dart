abstract class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthLoggedIn extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  final String role;

  AuthLoggedIn({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });
}

class AuthLoggedOut extends AuthEvent {}
