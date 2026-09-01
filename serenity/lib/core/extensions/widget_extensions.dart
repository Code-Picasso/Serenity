import 'package:flutter/material.dart';

/// Layout helpers that keep UI code terse and expressive.
extension WidgetX on Widget {
  Widget pad([EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md)]) =>
      Padding(padding: padding, child: this);

  Widget padAll(double value) => Padding(padding: EdgeInsets.all(value), child: this);

  Widget padSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical), child: this);

  Widget center() => Center(child: this);

  Widget align(Alignment alignment) => Align(alignment: alignment, child: this);

  Widget onTap(VoidCallback? onTap) =>
      GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: this);

  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);
}

/// Spacing scale — const values avoid re-allocating layout numbers per build.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}
