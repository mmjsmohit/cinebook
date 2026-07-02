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
