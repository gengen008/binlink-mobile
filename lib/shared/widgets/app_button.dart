import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost, dark }

class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadow, borderColor) = _colors();

    return GestureDetector(
      onTapDown: (_) => widget.onPressed != null ? _scaleCtrl.reverse() : null,
      onTapUp: (_) => widget.onPressed != null ? _scaleCtrl.forward() : null,
      onTapCancel: () => widget.onPressed != null ? _scaleCtrl.forward() : null,
      onTap: (widget.loading || widget.onPressed == null) ? null : () {
        HapticFeedback.lightImpact();
        widget.onPressed!();
      },
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.mdBR,
            border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
            boxShadow: shadow != null ? [
              BoxShadow(color: shadow.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
            ] : null,
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: fg),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
                      Text(
                        widget.label,
                        style: AppTextStyles.button.copyWith(color: fg),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?, Color?) _colors() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (AppColors.primary, Colors.white, AppColors.primary, null);
      case AppButtonVariant.secondary:
        return (Colors.white, AppColors.textPrimary, null, AppColors.border);
      case AppButtonVariant.danger:
        return (AppColors.danger, Colors.white, AppColors.danger, null);
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.primary, null, null);
      case AppButtonVariant.dark:
        return (AppColors.black, Colors.white, Colors.black, null);
    }
  }
}
