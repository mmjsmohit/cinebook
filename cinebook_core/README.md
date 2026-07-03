# CineBook Core Package (`cinebook_core`)

`cinebook_core` is a shared Dart plumbing package used by both the Customer App (`cinebook_user_app`) and the Hall Manager App (`cinebook_hall_app`). It abstracts network interactions, JWT authorization persistence, and data models to avoid codebase duplication.

## 1. Package Architecture

This package maintains a strict separation from the UI layers of the applications.

```
lib/
├── src/
│   ├── api/
│   │   ├── api_client.dart       # Dio HTTP client wrapper
│   │   └── endpoints.dart        # API routing dictionary
│   ├── auth/
│   │   └── token_storage.dart    # flutter_secure_storage client wrapper
│   └── models/                   # Standard deserializable Dart DTOs
│       ├── movie.dart
│       ├── show.dart
│       ├── seat.dart
│       └── booking.dart
└── cinebook_core.dart            # Primary library exports
```

---

## 2. Key Features

### Intercepted API Client
- Uses the `Dio` library wrapper for all network requests.
- Contains an authentication interceptor that automatically reads the access JWT from secure storage and injects it into request headers.
- Implements a retry interceptor. On receiving a `401 Unauthorized` status, it triggers a refresh-token call to `/auth/refresh` behind the scenes, updates the secure storage, and replays the failed request transparently.

### Secure Token Manager
- Uses `flutter_secure_storage` to persist tokens safely inside Android's KeyStore and iOS's Keychain.
- Manages persistence of User roles and session details so users remain logged in across application cold starts.

---

## 3. Usage Guide

To use this shared package in the Flutter applications, include it as a local path dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cinebook_core:
    path: ../cinebook_core
```

Initialize the clients inside your main execution loop:
```dart
import 'package:cinebook_core/cinebook_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(
    baseUrl: 'http://localhost:3000',
    tokenStorage: tokenStorage,
  );

  runApp(MyApp(apiClient: apiClient));
}
```
