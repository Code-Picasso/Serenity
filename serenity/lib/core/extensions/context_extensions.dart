import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

/// Context helpers that shorten theme/media lookups and navigation.
/// Keeps build methods lean and avoids repeated `Theme.of(context)` calls.
extension BuildContextX on BuildContext {
  AppThemeExtension get themeExt =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.dark;

  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ---- Navigation (native Navigator) ----
  Future<T?> push<T extends Object?>(String route, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(route, arguments: arguments);

  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(String route, {Object? arguments}) =>
      Navigator.of(this).pushReplacementNamed<T, TO>(route, arguments: arguments);

  Future<T?> pushAndRemoveUntil<T extends Object?>(String route) =>
      Navigator.of(this).pushNamedAndRemoveUntil<T>(route, (r) => false);

  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop(result);

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
