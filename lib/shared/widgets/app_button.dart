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

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: variant == AppButtonVariant.primary
              ? AppColors.primaryGradient
              : null,
          color: variant == AppButtonVariant.primary ? null : bg,
          borderRadius: AppRadius.smBR,
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: AppRadius.smBR,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        Text(label, style: AppTextStyles.button.copyWith(color: fg)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _colors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return (AppColors.steelBlue, AppColors.white, null);
      case AppButtonVariant.secondary:
        return (AppColors.card, AppColors.skyBlue, AppColors.border);
      case AppButtonVariant.danger:
        return (AppColors.danger.withAlpha(20), AppColors.danger, AppColors.danger.withAlpha(80));
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.skyBlue, null);
    }
  }
}
