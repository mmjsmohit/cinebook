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
