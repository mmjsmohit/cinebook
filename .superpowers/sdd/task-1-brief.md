### Task 1: Bootstrap Flutter Workspace
Create the flutter project structure:
1. `cinebook_user_app` (Flutter app for customers)
2. `cinebook_hall_app` (Flutter app for hall managers)
3. `cinebook_core` (Flutter package for shared logic, DTOs, API client)

Add dependencies to `cinebook_core`: `dio`, `flutter_bloc`, `flutter_secure_storage`.
Link `cinebook_core` to both apps via a local `path:` dependency.
Set up a basic `main.dart` with `MaterialApp` in both apps.

