import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design_system/app_motion.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_haptics.dart';
import '../../app.dart'; // For extension

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.binlinkColors;
    final typography = context.binlinkTypography;
    
    final (bg, text, border) = _getColors(colors);
    final isEnabled = onPressed != null && !isLoading;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBR,
        side: border != null ? BorderSide(color: border, width: 1.5) : BorderSide.none,
      ),
      disabledBackgroundColor: bg.withOpacity(0.5),
      disabledForegroundColor: text.withOpacity(0.7),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label, style: typography.button),
        ],
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 56,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isEnabled ? () {
          AppHaptics.light();
          onPressed?.call();
        } : null,
        child: content,
      ),
    ).animate(target: isEnabled ? 1 : 0).scale(
      begin: const Offset(1, 1),
      end: const Offset(1, 1), // Standard scale
      duration: AppMotion.fast,
    );
  }

  (Color, Color, Color?) _getColors(dynamic colors) {
    switch (variant) {
      case AppButtonVariant.primary:
        return (colors.primary, Colors.white, null);
      case AppButtonVariant.secondary:
        return (colors.surface, colors.textPrimary, colors.border);
      case AppButtonVariant.ghost:
        return (Colors.transparent, colors.primary, null);
      case AppButtonVariant.danger:
        return (colors.danger, Colors.white, null);
    }
  }
}
