### Task 3: Overhaul user app screens to use theme tokens

**Files:**
- Modify: `cinebook_user_app/lib/screens/login_screen.dart`
- Modify: `cinebook_user_app/lib/screens/main_screen.dart`
- Modify: `cinebook_user_app/lib/screens/home_screen.dart`
- Modify: `cinebook_user_app/lib/screens/movie_detail_screen.dart`
- Modify: `cinebook_user_app/lib/screens/showtimes_screen.dart`
- Modify: `cinebook_user_app/lib/screens/payment_screen.dart`
- Modify: `cinebook_user_app/lib/screens/confirmation_screen.dart`
- Modify: `cinebook_user_app/lib/screens/history_screen.dart`
- Modify: `cinebook_user_app/lib/screens/booking_details_screen.dart`

**Interfaces:**
- Consumes: `CinemaColors`, `CinemaThemeExtension`, `Theme.of(context)` (from Task 1 & 2)
- Produces: all user-facing screens render with cinema tokens; zero raw `Colors.*` remain in these files

- [ ] **Step 1: Refactor login_screen.dart**

Replace hardcoded styles in `cinebook_user_app/lib/screens/login_screen.dart`. No raw `Colors.*` should remain. The `ElevatedButton` and `TextField` will inherit from the theme automatically, so the main changes are:
- Remove `const Text('Login to CineBook')` appBar title and let it use the theme's `appBarTheme.titleTextStyle`.
- No other explicit style changes needed since `InputDecorationTheme` and `ElevatedButtonThemeData` handle the rest.

Verify the file has zero `Colors.` references.

- [ ] **Step 2: Refactor main_screen.dart**

In `cinebook_user_app/lib/screens/main_screen.dart`:
- The `NavigationBar` will inherit from `navigationBarTheme` automatically — no changes needed for icons/labels.
- The `AppBar` will inherit from `appBarTheme`.

Verify the file has zero `Colors.` references.

- [ ] **Step 3: Refactor home_screen.dart**

In `cinebook_user_app/lib/screens/home_screen.dart`:
- The `ListTile` text styles are inherited.
- Replace `const Icon(Icons.movie, size: 50)` placeholder color (currently default white) — wrap with themed color: `Icon(Icons.movie, size: 50, color: CinemaColors.steelGray)`.

Add import: `import 'package:cinebook_core/cinebook_core.dart';` (already present).

- [ ] **Step 4: Refactor movie_detail_screen.dart**

In `cinebook_user_app/lib/screens/movie_detail_screen.dart`:
- `Theme.of(context).textTheme.headlineMedium` on line 55 already uses theme — keep as-is.
- `Theme.of(context).textTheme.titleLarge` on line 64 already uses theme — keep as-is.
- The `ElevatedButton` inherits styling.
- Replace the `errorBuilder` fallback icon's implicit color with `CinemaColors.steelGray`.

Verify zero raw `Colors.*`.

- [ ] **Step 5: Refactor showtimes_screen.dart**

In `cinebook_user_app/lib/screens/showtimes_screen.dart`:
- Line 65: replace `Theme.of(context).cardColor` with `CinemaColors.inkCharcoal`.
- Lines 81–83: replace `Theme.of(context).colorScheme.primary` with `CinemaColors.neonRed`, and `Colors.grey` border with `CinemaColors.structuralBorder`.
- Lines 88–89: replace `Colors.white` with `CinemaColors.offWhite`, `Colors.grey` with `CinemaColors.steelGray`.
- Line 142: replace `Colors.green` border with `CinemaColors.successGreen`.
- Line 146: replace `Colors.green` text color with `CinemaColors.successGreen`.
- Line 148: replace `Colors.grey` with `CinemaColors.steelGray`.

- [ ] **Step 6: Refactor payment_screen.dart**

In `cinebook_user_app/lib/screens/payment_screen.dart`:
- The `CircularProgressIndicator` inherits neon red from `progressIndicatorTheme`.
- The `ElevatedButton` inherits from `elevatedButtonTheme`.
- No raw colors to remove.

Verify zero raw `Colors.*`.

- [ ] **Step 7: Refactor confirmation_screen.dart**

In `cinebook_user_app/lib/screens/confirmation_screen.dart`:
- Line 15: replace `Colors.green` with `CinemaColors.successGreen` for the check icon.
- The `ElevatedButton` inherits styling.

Add import: `import 'package:cinebook_core/cinebook_core.dart';`

- [ ] **Step 8: Refactor history_screen.dart**

In `cinebook_user_app/lib/screens/history_screen.dart`:
- Line 71: replace `Colors.red` with `CinemaColors.neonRed` for the cancel button text.

- [ ] **Step 9: Refactor booking_details_screen.dart**

In `cinebook_user_app/lib/screens/booking_details_screen.dart`:
- Lines 112–115: replace `Colors.grey[800]` poster fallback with `CinemaColors.inkCharcoal`, `Colors.white54` with `CinemaColors.steelGray`.
- Lines 130–131: replace `Colors.grey` with `CinemaColors.steelGray`.
- Line 159: replace `Colors.grey` icon with `CinemaColors.steelGray`.
- Line 165: replace `Colors.grey` label with `CinemaColors.steelGray`.
- Lines 179–183: replace `Theme.of(context).cardColor` with `CinemaColors.inkCharcoal`, `Colors.grey.withOpacity(0.2)` border with `CinemaColors.structuralBorder`.
- Lines 192, 198: replace `Colors.grey` with `CinemaColors.steelGray`.
- Lines 213–219: replace `_getStatusColor` method: `CONFIRMED` → `CinemaColors.successGreen`, `CANCELLED` → `CinemaColors.neonRed`, `PENDING` → `CinemaColors.warmAmber`, default → `CinemaColors.steelGray`.

- [ ] **Step 10: Verify user app analyzes cleanly**

Run: `cd cinebook_user_app && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 11: Commit**

```bash
git add cinebook_user_app/lib/screens/
git commit -m "refactor(user-app): replace all raw Colors with CinemaTheme tokens across screens"
```

---

