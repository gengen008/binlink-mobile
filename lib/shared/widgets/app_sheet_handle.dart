import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Drag handle for modal bottom sheets — Rydr's sheetHeader pattern.
///
/// Rydr: bare function sheetHeader() returning a Container.
/// Fixed: proper StatelessWidget with const constructor, tokens.
///
/// Usage:
///   const AppSheetHandle()
///   — or with padding override —
///   const AppSheetHandle(topPadding: 16, bottomPadding: 8)
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({
    super.key,
    this.topPadding    = 12.0,
    this.bottomPadding = 8.0,
    this.color,
  });

  final double topPadding;
  final double bottomPadding;
  /// Defaults to AppColors.sheetHandle.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        bottom: bottomPadding,
      ),
      child: Center(
        child: Container(
          // Rydr dimensions: 80px wide, 2.875px tall
          width: AppSpacing.sheetHandleW,
          height: AppSpacing.sheetHandleH,
          decoration: BoxDecoration(
            color: color ?? AppColors.sheetHandle,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}
