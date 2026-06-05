import 'package:flutter/material.dart';

/// BinLink Eco — Spacing Tokens
class AppSpacing {
  AppSpacing._();

  static const double s2   = 2.0;
  static const double s4   = 4.0;
  static const double s5   = 5.0;
  static const double s8   = 8.0;
  static const double s10  = 10.0;
  static const double s12  = 12.0;
  static const double s14  = 14.0;
  static const double s16  = 16.0;
  static const double s20  = 20.0;
  static const double s24  = 24.0;
  static const double s28  = 28.0;
  static const double s32  = 32.0;
  static const double s40  = 40.0;
  static const double s48  = 48.0;
  static const double s56  = 56.0;
  static const double s64  = 64.0;
  static const double s80  = 80.0;
  static const double s100 = 100.0;

  // ── Legacy aliases ─────────────────────────────────────────────────────────
  static const double s7  = 7.0;
  static const double s15 = 15.0;
  static const double s25 = 25.0;
  static const double s30 = 30.0;
  static const double s50 = 50.0;
  static const double s60 = 60.0;

  /// Standard horizontal page padding
  static const double pagePaddingH = 24.0;

  /// Standard vertical page padding
  static const double pagePaddingV = 20.0;

  /// Primary button height
  static const double buttonHeight = 56.0;

  /// AppBar preferred height
  static const double appBarHeight = 64.0;

  /// Bottom sheet drag handle width
  static const double sheetHandleW = 48.0;

  /// Bottom sheet drag handle height
  static const double sheetHandleH = 4.0;

  /// Bottom panel height (map home screen)
  static const double bottomPanelH = 320.0;
}

/// Horizontal gap widget
class XGap extends StatelessWidget {
  final double x;
  const XGap(this.x, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(width: x);
}

/// Vertical gap widget
class YGap extends StatelessWidget {
  final double y;
  const YGap(this.y, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: y);
}

/// BuildContext extension for responsive sizing
extension AppScreenSize on BuildContext {
  double screenHeight([double percent = 1]) =>
      MediaQuery.sizeOf(this).height * percent;

  double screenWidth([double percent = 1]) =>
      MediaQuery.sizeOf(this).width * percent;
}
