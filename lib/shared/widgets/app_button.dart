import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
    this.height = 56,
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
    final (bg, fg, border) = _colors();

    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: AppRadius.buttonBR,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.buttonBR,
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize:
                      fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
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
        return (AppColors.primary, Colors.white, null);
      case AppButtonVariant.secondary:
        return (AppColors.fieldFill, AppColors.secondary, AppColors.border);
      case AppButtonVariant.danger:
        return (
          AppColors.danger.withAlpha(20),
          AppColors.danger,
          AppColors.danger.withAlpha(80),
        );
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.secondary, null);
    }
  }
}
