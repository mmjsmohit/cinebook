# CineBook Theme Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the vanilla Material UI defaults across both Flutter apps with a unified, custom "Immersive Cinema" dark theme powered by shared design tokens in `cinebook_core`.

**Architecture:** Three new theme files in `cinebook_core/lib/src/theme/` (`cinema_colors.dart`, `cinema_theme_extension.dart`, `cinema_theme.dart`) define the full design system. Both `cinebook_user_app` and `cinebook_hall_app` swap their ad-hoc `ThemeData` for `CinemaTheme.darkTheme`. Each screen is then updated to remove hardcoded `Colors.*` references in favor of theme-resolved values.

**Tech Stack:** Flutter 3.12+, Material 3, `google_fonts` ^6.2.0, `ThemeExtension` API

## Global Constraints

- All colors come from `CinemaColors` constants or `Theme.of(context)`. Zero raw `Colors.*` or `Color(0xFF...)` in screen files.
- All custom properties (neon glow, seat state colors) come from `Theme.of(context).extension<CinemaThemeExtension>()`.
- Typography uses `Theme.of(context).textTheme.*` everywhere. No inline `GoogleFonts.*` calls in screens.
- Run `flutter analyze` after every task to verify zero analysis errors.
- Commit after every task.

---

### Task 1: Create the shared theme files in cinebook_core

**Files:**
- Create: `cinebook_core/lib/src/theme/cinema_colors.dart`
- Create: `cinebook_core/lib/src/theme/cinema_theme_extension.dart`
- Create: `cinebook_core/lib/src/theme/cinema_theme.dart`
- Modify: `cinebook_core/pubspec.yaml`
- Modify: `cinebook_core/lib/cinebook_core.dart`

**Interfaces:**
- Consumes: nothing (foundational task)
- Produces: `CinemaColors` (static color constants), `CinemaThemeExtension` (custom ThemeExtension with `neonGlow`, `seatAvailable`, `seatSelected`, `seatSold`, `structuralBorder`), `CinemaTheme.darkTheme` (fully configured `ThemeData`)

- [ ] **Step 1: Add google_fonts dependency to cinebook_core**

In `cinebook_core/pubspec.yaml`, add `google_fonts` under `dependencies`:

```yaml
dependencies:
  dio: ^5.10.0
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  flutter_secure_storage: ^10.3.1
  google_fonts: ^6.2.0
```

- [ ] **Step 2: Run pub get to install the dependency**

Run: `cd cinebook_core && flutter pub get`
Expected: "Got dependencies!" with no errors.

- [ ] **Step 3: Create cinema_colors.dart**

Create `cinebook_core/lib/src/theme/cinema_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// CineBook design system color palette.
///
/// All hex values are sourced from DESIGN.md and must not be overridden
/// in consumer apps. Use [CinemaThemeExtension] for semantic aliases.
class CinemaColors {
  CinemaColors._();

  // ── Brand Accents ──────────────────────────────────────────────
  static const Color neonRed      = Color(0xFFFF2E51);
  static const Color neonRedDeep  = Color(0xFFE01B3C);
  static const Color warmAmber    = Color(0xFFFF9F0A);
  static const Color successGreen = Color(0xFF30D158);

  // ── Neutrals ──────────────────────────────────────────────────
  static const Color deepCharcoal    = Color(0xFF0B0C0E);
  static const Color inkCharcoal     = Color(0xFF16181C);
  static const Color steelGray       = Color(0xFF8E939E);
  static const Color structuralBorder = Color(0xFF2C2E35);
  static const Color offWhite        = Color(0xFFF5F6F8);
}
```

- [ ] **Step 4: Create cinema_theme_extension.dart**

Create `cinebook_core/lib/src/theme/cinema_theme_extension.dart`:

```dart
import 'package:flutter/material.dart';
import 'cinema_colors.dart';

/// Custom theme properties outside standard Material roles.
///
/// Access via `Theme.of(context).extension<CinemaThemeExtension>()`.
class CinemaThemeExtension extends ThemeExtension<CinemaThemeExtension> {
  final List<BoxShadow>? neonGlow;
  final Color? seatAvailable;
  final Color? seatSelected;
  final Color? seatSold;
  final Color? structuralBorder;

  const CinemaThemeExtension({
    required this.neonGlow,
    required this.seatAvailable,
    required this.seatSelected,
    required this.seatSold,
    required this.structuralBorder,
  });

  @override
  CinemaThemeExtension copyWith({
    List<BoxShadow>? neonGlow,
    Color? seatAvailable,
    Color? seatSelected,
    Color? seatSold,
    Color? structuralBorder,
  }) {
    return CinemaThemeExtension(
      neonGlow: neonGlow ?? this.neonGlow,
      seatAvailable: seatAvailable ?? this.seatAvailable,
      seatSelected: seatSelected ?? this.seatSelected,
      seatSold: seatSold ?? this.seatSold,
      structuralBorder: structuralBorder ?? this.structuralBorder,
    );
  }

  @override
  CinemaThemeExtension lerp(
    covariant ThemeExtension<CinemaThemeExtension>? other,
    double t,
  ) {
    if (other is! CinemaThemeExtension) return this;
    return CinemaThemeExtension(
      neonGlow: BoxShadow.lerpList(neonGlow, other.neonGlow, t),
      seatAvailable: Color.lerp(seatAvailable, other.seatAvailable, t),
      seatSelected: Color.lerp(seatSelected, other.seatSelected, t),
      seatSold: Color.lerp(seatSold, other.seatSold, t),
      structuralBorder: Color.lerp(structuralBorder, other.structuralBorder, t),
    );
  }

  /// Pre-configured dark-mode instance.
  static const CinemaThemeExtension dark = CinemaThemeExtension(
    neonGlow: [
      BoxShadow(
        color: Color(0x66FF2E51),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
    seatAvailable: CinemaColors.successGreen,
    seatSelected: CinemaColors.neonRed,
    seatSold: CinemaColors.structuralBorder,
    structuralBorder: CinemaColors.structuralBorder,
  );
}
```

- [ ] **Step 5: Create cinema_theme.dart**

Create `cinebook_core/lib/src/theme/cinema_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cinema_colors.dart';
import 'cinema_theme_extension.dart';

/// Canonical CineBook theme. Both consumer apps use [darkTheme].
class CinemaTheme {
  CinemaTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: CinemaColors.deepCharcoal,

      colorScheme: ColorScheme.fromSeed(
        seedColor: CinemaColors.neonRed,
        primary: CinemaColors.neonRed,
        secondary: CinemaColors.warmAmber,
        surface: CinemaColors.inkCharcoal,
        onSurface: CinemaColors.offWhite,
        brightness: Brightness.dark,
      ),

      textTheme: _buildTextTheme(base.textTheme),

      appBarTheme: AppBarTheme(
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CinemaColors.offWhite,
        ),
        iconTheme: const IconThemeData(color: CinemaColors.offWhite),
      ),

      cardTheme: const CardThemeData(
        color: CinemaColors.inkCharcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: CinemaColors.structuralBorder),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CinemaColors.neonRed,
          foregroundColor: CinemaColors.offWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CinemaColors.neonRed,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CinemaColors.neonRed,
          foregroundColor: CinemaColors.offWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CinemaColors.inkCharcoal,
        labelStyle: GoogleFonts.inter(color: CinemaColors.steelGray),
        hintStyle: GoogleFonts.inter(color: CinemaColors.steelGray),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: CinemaColors.structuralBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: CinemaColors.structuralBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: CinemaColors.neonRed, width: 2),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: CinemaColors.structuralBorder,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: CinemaColors.inkCharcoal,
        contentTextStyle: GoogleFonts.inter(color: CinemaColors.offWhite),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: CinemaColors.structuralBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CinemaColors.deepCharcoal,
        indicatorColor: CinemaColors.neonRed.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CinemaColors.neonRed);
          }
          return const IconThemeData(color: CinemaColors.steelGray);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CinemaColors.neonRed,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            color: CinemaColors.steelGray,
          );
        }),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: CinemaColors.inkCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: CinemaColors.structuralBorder),
        ),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: CinemaColors.deepCharcoal,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: CinemaColors.inkCharcoal,
        selectedColor: CinemaColors.neonRed,
        side: const BorderSide(color: CinemaColors.structuralBorder),
        labelStyle: GoogleFonts.inter(color: CinemaColors.offWhite),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CinemaColors.neonRed,
      ),

      extensions: <ThemeExtension<dynamic>>[
        CinemaThemeExtension.dark,
      ],
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: CinemaColors.offWhite,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: CinemaColors.offWhite,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: CinemaColors.offWhite,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: CinemaColors.offWhite,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: CinemaColors.offWhite,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: CinemaColors.offWhite,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: CinemaColors.offWhite,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: CinemaColors.steelGray,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: CinemaColors.steelGray,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CinemaColors.offWhite,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: CinemaColors.steelGray,
      ),
    );
  }
}
```

- [ ] **Step 6: Export theme files in cinebook_core barrel**

Modify `cinebook_core/lib/cinebook_core.dart` — append these three lines:

```dart
export 'src/theme/cinema_colors.dart';
export 'src/theme/cinema_theme_extension.dart';
export 'src/theme/cinema_theme.dart';
```

- [ ] **Step 7: Verify the shared package compiles**

Run: `cd cinebook_core && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add cinebook_core/
git commit -m "feat(core): add CinemaTheme design system with colors, extensions, and ThemeData"
```

---

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

### Task 4: Overhaul seat map screen to use CinemaThemeExtension

**Files:**
- Modify: `cinebook_user_app/lib/screens/seat_map_screen.dart`

**Interfaces:**
- Consumes: `CinemaColors`, `CinemaThemeExtension` (from Task 1)
- Produces: seat map renders with cinema-branded seat colors, the bottom action bar uses dark theme instead of white

- [ ] **Step 1: Refactor seat colors to use CinemaThemeExtension**

In `cinebook_user_app/lib/screens/seat_map_screen.dart`, update the `_SeatMapViewState.build` method. Replace the hardcoded color assignments (lines 133–148) with theme-resolved values:

```dart
final cinema = Theme.of(context).extension<CinemaThemeExtension>()!;

Color bgColor = Colors.transparent;
Color borderColor = cinema.seatAvailable!;
Color textColor = cinema.seatAvailable!;

if (seatState == 'booked') {
  bgColor = cinema.seatSold!;
  borderColor = cinema.seatSold!;
  textColor = CinemaColors.steelGray;
} else if (seatState == 'held' && !isMyHold) {
  bgColor = cinema.seatSold!;
  borderColor = cinema.seatSold!;
  textColor = CinemaColors.steelGray;
} else if (isMyHold) {
  bgColor = cinema.seatSelected!;
  textColor = CinemaColors.offWhite;
}
```

- [ ] **Step 2: Refactor the legend row**

Replace the legend colors (lines 191–196):

```dart
_buildLegendItem('Available', Colors.transparent, cinema.seatAvailable!),
const SizedBox(width: 16),
_buildLegendItem('Selected', cinema.seatSelected!, cinema.seatSelected!),
const SizedBox(width: 16),
_buildLegendItem('Sold', cinema.seatSold!, cinema.seatSold!),
```

- [ ] **Step 3: Replace the white bottom action bar**

Replace the white `Container` bottom bar (lines 202–233). Change `Colors.white` background and shadow to dark theme values:

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: CinemaColors.inkCharcoal,
    border: const Border(
      top: BorderSide(color: CinemaColors.structuralBorder),
    ),
  ),
  child: SafeArea(
    top: false,
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () { /* existing navigation logic */ },
        child: Text(
          'Pay ₹$totalPrice',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ),
),
```

The `ElevatedButton` style is inherited from `CinemaTheme.darkTheme` (neon red background, off-white text). Remove the explicit `style:` and `TextStyle(color: Colors.white)`.

- [ ] **Step 4: Replace category header colors**

Line 106: replace `Colors.white70` with `CinemaColors.steelGray`.
Line 109: replace `Colors.white24` divider with `CinemaColors.structuralBorder`.
Line 121: replace `Colors.white54` row label with `CinemaColors.steelGray`.

- [ ] **Step 5: Verify seat map screen analyzes cleanly**

Run: `cd cinebook_user_app && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add cinebook_user_app/lib/screens/seat_map_screen.dart
git commit -m "refactor(seat-map): apply CinemaThemeExtension to seat colors and bottom bar"
```

---

### Task 5: Overhaul agent chat screen to use theme tokens

**Files:**
- Modify: `cinebook_user_app/lib/screens/agent_screen.dart`

**Interfaces:**
- Consumes: `CinemaColors`, `CinemaThemeExtension` (from Task 1)
- Produces: chat screen renders with cinema-branded colors for hold banners, movie cards, booking summaries, and payment results

- [ ] **Step 1: Refactor the hold banner**

Replace the amber banner (lines 144–161). Change `Colors.amber.shade100` background to `CinemaColors.warmAmber` with 15% opacity, `Colors.amber` icon to `CinemaColors.warmAmber`, and `Colors.amber.shade900` text to `CinemaColors.offWhite`:

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: CinemaColors.warmAmber.withValues(alpha: 0.15),
    border: const Border(
      bottom: BorderSide(color: CinemaColors.structuralBorder),
    ),
  ),
  child: Row(
    children: [
      const Icon(Icons.timer, color: CinemaColors.warmAmber),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'You have seats on hold. Please confirm booking before the hold expires.',
          style: TextStyle(
            color: CinemaColors.offWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 2: Refactor _buildMovieList colors**

Replace `Colors.grey[800]` (lines 255, 264) with `CinemaColors.inkCharcoal`.
Replace `Colors.white54` (lines 258, 267) with `CinemaColors.steelGray`.

- [ ] **Step 3: Refactor _buildMovieCard colors**

Replace `Colors.grey[800]` (lines 305, 315) with `CinemaColors.inkCharcoal`.
Replace `Colors.white54` (lines 306, 316) with `CinemaColors.steelGray`.
Replace `Colors.grey` (line 335) with `CinemaColors.steelGray`.

- [ ] **Step 4: Refactor _buildSeatMapPreview colors**

Replace `Colors.grey` (lines 370, 381) with `CinemaColors.structuralBorder` for the border, and `CinemaColors.steelGray` for the icon.

- [ ] **Step 5: Refactor _buildBookingSummary colors**

Replace `Colors.deepPurple.withOpacity(0.1)` (line 390) with `CinemaColors.inkCharcoal`.

- [ ] **Step 6: Refactor _buildPaymentResult colors**

Replace `Colors.green` references with `CinemaColors.successGreen` and `Colors.red` with `CinemaColors.neonRed`:

```dart
Widget _buildPaymentResult(Map<String, dynamic> data) {
  final success = data['status'] == 'success';
  final statusColor = success ? CinemaColors.successGreen : CinemaColors.neonRed;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: statusColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: statusColor),
    ),
    child: Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.error,
          color: statusColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            data['message'] ??
                (success ? 'Payment successful' : 'Payment failed'),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 7: Verify agent screen analyzes cleanly**

Run: `cd cinebook_user_app && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add cinebook_user_app/lib/screens/agent_screen.dart
git commit -m "refactor(agent): replace all raw Colors with CinemaTheme tokens in chat screen"
```

---

### Task 6: Overhaul hall manager app screens to use theme tokens

**Files:**
- Modify: `cinebook_hall_app/lib/screens/login_screen.dart`
- Modify: `cinebook_hall_app/lib/screens/screens_list_screen.dart`
- Modify: `cinebook_hall_app/lib/screens/show_calendar_screen.dart`
- Modify: `cinebook_hall_app/lib/screens/show_form_screen.dart`

**Interfaces:**
- Consumes: `CinemaColors`, `CinemaTheme.darkTheme` (from Tasks 1–2)
- Produces: all hall manager screens render with cinema tokens; zero raw `Colors.*` remain

- [ ] **Step 1: Audit and refactor login_screen.dart**

Open `cinebook_hall_app/lib/screens/login_screen.dart`. Replace any raw `Colors.*` with `CinemaColors.*` equivalents. The `ElevatedButton` and `TextField` are inherited from the theme.

- [ ] **Step 2: Audit and refactor screens_list_screen.dart**

Open `cinebook_hall_app/lib/screens/screens_list_screen.dart`. Replace any raw `Colors.*` references with `CinemaColors.*`.

- [ ] **Step 3: Audit and refactor show_calendar_screen.dart**

Open `cinebook_hall_app/lib/screens/show_calendar_screen.dart`. Replace any raw `Colors.*` with `CinemaColors.*`.

- [ ] **Step 4: Audit and refactor show_form_screen.dart**

Open `cinebook_hall_app/lib/screens/show_form_screen.dart`. Replace any raw `Colors.*` with `CinemaColors.*`.

- [ ] **Step 5: Verify hall app analyzes cleanly**

Run: `cd cinebook_hall_app && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add cinebook_hall_app/lib/screens/
git commit -m "refactor(hall-app): replace all raw Colors with CinemaTheme tokens across screens"
```

---

### Task 7: Final audit — zero raw Colors remaining

**Files:**
- All files in `cinebook_user_app/lib/` and `cinebook_hall_app/lib/`

**Interfaces:**
- Consumes: all previous tasks
- Produces: verified guarantee that no raw `Colors.*` or `Color(0xFF...)` literals remain in any screen file

- [ ] **Step 1: Grep for remaining raw Colors references in user app**

Run: `grep -rn 'Colors\.' cinebook_user_app/lib/ --include='*.dart' | grep -v 'CinemaColors' | grep -v '//'`
Expected: zero matches (empty output). If any remain, fix them by replacing with the appropriate `CinemaColors.*` constant.

- [ ] **Step 2: Grep for remaining raw Colors references in hall app**

Run: `grep -rn 'Colors\.' cinebook_hall_app/lib/ --include='*.dart' | grep -v 'CinemaColors' | grep -v '//'`
Expected: zero matches. Fix any remainders.

- [ ] **Step 3: Grep for remaining raw Color() constructors**

Run: `grep -rn 'Color(0x' cinebook_user_app/lib/ cinebook_hall_app/lib/ --include='*.dart'`
Expected: zero matches. Fix any remainders.

- [ ] **Step 4: Run flutter analyze on both apps**

Run: `cd cinebook_user_app && flutter analyze && cd ../cinebook_hall_app && flutter analyze`
Expected: "No issues found!" for both.

- [ ] **Step 5: Commit any remaining fixes**

```bash
git add -A
git commit -m "refactor: final audit — zero raw Colors remaining across both apps"
```
