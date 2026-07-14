import 'package:flutter/material.dart';

/// LEVM color palette — friendly-learning + positive energy.
///
/// - Indigo / violet = main brand (study, trust)
/// - Coral / amber    = accents for gamification (XP, streak, achievements)
class AppColors {
  AppColors._();

  // Brand
  static const Color brandPrimary = Color(0xFF5B5BF6); // Indigo
  static const Color brandSecondary = Color(0xFF8A4FFF); // Violet
  static const Color brandTertiary = Color(0xFF3F8CFF); // Sky blue

  // Gamification accents
  static const Color xp = Color(0xFFFFB020); // Amber
  static const Color streak = Color(0xFFFF6B3D); // Coral
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF0F8);
  static const Color lightTextPrimary = Color(0xFF15172B);
  static const Color lightTextSecondary = Color(0xFF5B5F77);
  static const Color lightBorder = Color(0xFFE2E5F1);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F1020);
  static const Color darkSurface = Color(0xFF181A30);
  static const Color darkSurfaceAlt = Color(0xFF22243C);
  static const Color darkTextPrimary = Color(0xFFF2F3FA);
  static const Color darkTextSecondary = Color(0xFFA7ABBE);
  static const Color darkBorder = Color(0xFF2C2F4A);

  // Gradient for hero areas
  static const List<Color> brandGradient = [
    Color(0xFF5B5BF6),
    Color(0xFF8A4FFF),
  ];

  static const List<Color> streakGradient = [
    Color(0xFFFF8A4F),
    Color(0xFFFFB020),
  ];
}
