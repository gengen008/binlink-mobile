import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost, dark }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final Widget? icon;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadow) = _colors();

    return GestureDetector(
      onTap: (loading || onPressed == null) ? null : () {
        HapticFeedback.lightImpact();
        onPressed!();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdBR,
          boxShadow: shadow != null ? [
            BoxShadow(color: shadow.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
          ] : null,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: fg),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 10)],
                    Text(
                      label,
                      style: AppTextStyles.button.copyWith(color: fg),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _colors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return (AppColors.primary, Colors.white, AppColors.primary);
      case AppButtonVariant.secondary:
        return (AppColors.surface, AppColors.textPrimary, null);
      case AppButtonVariant.danger:
        return (AppColors.danger, Colors.white, AppColors.danger);
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.primary, null);
      case AppButtonVariant.dark:
        return (AppColors.black, Colors.white, Colors.black);
    }
  }
}
