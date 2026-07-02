# Task 1 Report

## What was implemented
- Created the `TheatresScreen` widget in `cinebook_user_app/lib/screens/theatres_screen.dart`.
- The screen fetches data from the `/theatres` API using `ApiClient` and `dio.get`.
- Uses a clean, modern list style for displaying the theatres.
- Uses `CinemaColors` instead of raw Flutter `Colors` class.
- Adheres to typography using `Theme.of(context).textTheme.*`.

## What was tested and test results
- Ran `flutter analyze` static analysis successfully on `cinebook_user_app/`.
- No issues found after fixing one minor lint warning for unnecessary underscores.

## Files changed
- Added `cinebook_user_app/lib/screens/theatres_screen.dart`

## Self-review findings
- Checked that requirements were exactly met without overbuilding.
- Validated that `CinemaColors` and dynamic themes are accurately referenced.
- Ensured we correctly handle states: loading, empty, error, and loaded list of theatres.

## Any issues or concerns
- None. The task is fully complete.

## Task 1 Issue Fix Report
- Fixed crash risk in `_fetchTheatres()` by inserting `if (!mounted) return;` immediately after `await` in the `try` block, and also at the start of the `catch` block before calling `setState`.
- Ran `flutter analyze` and no issues were found.
