import 'package:flutter/material.dart';

/// The Serenity palette: black base with a burnt-orange accent
/// (derived from the app logo).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE4572E); // burnt orange
  static const Color primaryLight = Color(0xFFF07B52);
  static const Color primaryDark = Color(0xFFB83D1B);

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static const Color surfaceHigh = Color(0xFF232323);

  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF5C5C5C);

  static const Color error = Color(0xFFCF3B3B);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFE0A83C);
  static const Color divider = Color(0xFF2A2A2A);

  /// Gradient used for hero / splash surfaces.
  static const List<Color> brandGradient = [
    Color(0xFFE4572E),
    Color(0xFF8A2F16),
  ];
}
