import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

///
///  - Two separate classes (DotWidget, DrawerDots) doing the same thing — unified.
///  - totalWidth ~/ (dashWidth + emptyWidth) can return 0 → divide-by-zero guard.
///  - Hardcoded totalWidth (150px) doesn't respond to container width → LayoutBuilder.
///  - No const constructor on either class → fixed.
///
/// Usage:
///   const AppDotSeparator()            // full-width, default color
///   const AppDotSeparator(color: ...) // custom color
class AppDotSeparator extends StatelessWidget {
  const AppDotSeparator({
    super.key,
    this.dashWidth  = 6.0,
    this.dashHeight = 1.5,
    this.gapWidth   = 4.0,
    this.color,
    this.padding    = const EdgeInsets.symmetric(horizontal: 20),
  });

  final double dashWidth;
  final double dashHeight;
  final double gapWidth;
  /// Defaults to AppColors.border.
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.border;
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final available = constraints.maxWidth;
          final unitWidth = dashWidth + gapWidth;
          // Guard: avoid zero-count when available is smaller than one unit
          final count = unitWidth > 0
              ? (available / unitWidth).floor().clamp(1, 200)
              : 1;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: dashHeight,
                margin: EdgeInsets.only(right: gapWidth),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(dashHeight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
