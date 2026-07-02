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

