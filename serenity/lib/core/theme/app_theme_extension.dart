import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-specific theme tokens exposed through [ThemeExtension].
/// Access them with `context.themeExt` (see core/extensions/context_extensions.dart).
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color primary;
  final Color primaryLight;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHigh;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const AppThemeExtension({
    required this.primary,
    required this.primaryLight,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHigh,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  static const dark = AppThemeExtension(
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    surfaceHigh: AppColors.surfaceHigh,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
  );

  @override
  AppThemeExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHigh,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
  }) {
    return AppThemeExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t) ?? surfaceHigh,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
    );
  }
}
