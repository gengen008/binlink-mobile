import 'package:flutter/material.dart';

/// BinLink Design System — Spacing Tokens
///
/// Adopted from Rydr's XMargin/YMargin pattern with improvements:
/// - const constructors (Rydr's original lacked these)
/// - Fixed spacing scale (Rydr used arbitrary raw numbers)
/// - screenWidth/screenHeight extension (Rydr's CustomContext pattern)
class AppSpacing {
  AppSpacing._();

  static const double s2  = 2.0;
  static const double s4  = 4.0;
  static const double s5  = 5.0;
  static const double s7  = 7.0;
  static const double s8  = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s25 = 25.0;
  static const double s30 = 30.0;
  static const double s40 = 40.0;
  static const double s50 = 50.0;
  static const double s60 = 60.0;
  static const double s80 = 80.0;
  static const double s100 = 100.0;

  /// Standard horizontal page padding (matches Rydr's 30px symmetric)
  static const double pagePaddingH = 30.0;

  /// Standard vertical page padding
  static const double pagePaddingV = 20.0;

  /// Button height — matches Rydr's 50-52px
  static const double buttonHeight = 52.0;

  /// AppBar height — matches Rydr's 70-75px preferred size
  static const double appBarHeight = 70.0;

  /// Bottom sheet drag handle width (Rydr: 80px)
  static const double sheetHandleW = 80.0;

  /// Bottom sheet drag handle height (Rydr: 2.875px)
  static const double sheetHandleH = 3.0;
}

/// Horizontal gap — const-safe SizedBox width widget.
/// Replaces Rydr's XMargin(x) pattern.
class XGap extends StatelessWidget {
  final double x;
  const XGap(this.x, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(width: x);
}

/// Vertical gap — const-safe SizedBox height widget.
/// Replaces Rydr's YMargin(y) pattern.
class YGap extends StatelessWidget {
  final double y;
  const YGap(this.y, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: y);
}

/// BuildContext extension for responsive sizing.
/// Replaces Rydr's CustomContext extension.
extension AppScreenSize on BuildContext {
  /// Full screen height, optionally scaled by [percent].
  double screenHeight([double percent = 1]) =>
      MediaQuery.sizeOf(this).height * percent;

  /// Full screen width, optionally scaled by [percent].
  double screenWidth([double percent = 1]) =>
      MediaQuery.sizeOf(this).width * percent;
}
