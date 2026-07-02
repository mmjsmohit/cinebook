### Task 2: Wire CinemaTheme into both Flutter apps

**Files:**
- Modify: `cinebook_user_app/lib/main.dart:30-37`
- Modify: `cinebook_hall_app/lib/main.dart:29-36`
- Modify: `cinebook_user_app/pubspec.yaml` (may need `flutter pub get`)
- Modify: `cinebook_hall_app/pubspec.yaml` (may need `flutter pub get`)

**Interfaces:**
- Consumes: `CinemaTheme.darkTheme` from `cinebook_core`
- Produces: both apps render with the new dark theme; all default Material components inherit the cinema styling automatically

- [ ] **Step 1: Run pub get in both apps to pick up cinebook_core changes**

Run: `cd cinebook_user_app && flutter pub get && cd ../cinebook_hall_app && flutter pub get`
Expected: "Got dependencies!" for both.

- [ ] **Step 2: Replace the user app's ThemeData**

In `cinebook_user_app/lib/main.dart`, replace lines 32–37:

```dart
      // BEFORE:
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
```

with:

```dart
      theme: CinemaTheme.darkTheme,
```

The import `package:cinebook_core/cinebook_core.dart` is already present on line 3.

- [ ] **Step 3: Replace the hall app's ThemeData**

In `cinebook_hall_app/lib/main.dart`, replace lines 31–35:

```dart
      // BEFORE:
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
```

with:

```dart
      theme: CinemaTheme.darkTheme,
```

The import `package:cinebook_core/cinebook_core.dart` is already present on line 3.

- [ ] **Step 4: Verify both apps analyze cleanly**

Run: `cd cinebook_user_app && flutter analyze && cd ../cinebook_hall_app && flutter analyze`
Expected: "No issues found!" for both.

- [ ] **Step 5: Commit**

```bash
git add cinebook_user_app/lib/main.dart cinebook_hall_app/lib/main.dart
git commit -m "feat(apps): wire CinemaTheme.darkTheme into both Flutter apps"
```

---

