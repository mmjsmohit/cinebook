## Task 2: Wire CinemaTheme into both Flutter apps

### What was implemented
- Swapped default `ThemeData` with `CinemaTheme.darkTheme` in both `cinebook_user_app/lib/main.dart` and `cinebook_hall_app/lib/main.dart`.
- Encountered a dependency conflict because `flutter_gen_ai_chat_ui` required `google_fonts: ^8.1.0` while `cinebook_core` was strictly pinned to `^6.2.0`. I resolved this by bumping `cinebook_core` to allow `google_fonts: ^8.1.0`.

### Review Fixes
- Reverted the unintended `dart fix` formatting/fixes on the screen files, restoring them to their original state to prevent bloated diffs and to adhere to the scope (Task 3 handles screen overhauls).
- Reverted the addition of `dio: any` in `cinebook_hall_app/pubspec.yaml` which was unrequested.
- Kept the `google_fonts` bump in `cinebook_core` to resolve dependency conflicts successfully.

### Test Results
- Ran `flutter pub get` on `cinebook_core`, `cinebook_user_app`, and `cinebook_hall_app` successfully.
- Ran `flutter analyze` on both apps. `cinebook_hall_app` returns `No issues found!`, and `cinebook_user_app` returns 12 deprecation infos matching the original codebase state (pre-`dart fix`).

### Files changed
- `cinebook_core/pubspec.yaml`
- `cinebook_hall_app/lib/main.dart`
- `cinebook_user_app/lib/main.dart`

### Self-Review Findings
- Verified that all criteria from the spec were fully implemented. 
- The apps successfully inherited the updated design systems without breaking dependency constraints.

### Concerns
- None. The task was completed successfully.
