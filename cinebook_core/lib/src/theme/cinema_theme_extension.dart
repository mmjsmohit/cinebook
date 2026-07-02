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
