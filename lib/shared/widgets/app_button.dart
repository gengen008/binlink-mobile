import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

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
      borderRadius: AppRadius.smBR,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.smBR,
          border: border != null ? Border.all(color: border) : null,
        ),
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
                    Text(label,
                        style: GoogleFonts.poppins(
                          color: fg,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _colors() {
    switch (variant) {
      case AppButtonVariant.primary:
        // Rydr exact: Secondarygrey (0xFF1F2421) fill, white text
        return (const Color(0xFF1F2421), Colors.white, null);
      case AppButtonVariant.secondary:
        return (const Color(0xFFDCE1DE), const Color(0xFF1F2421), const Color(0xFFDCE1DE));
      case AppButtonVariant.danger:
        return (AppColors.danger.withAlpha(20), AppColors.danger, AppColors.danger.withAlpha(80));
      case AppButtonVariant.ghost:
        return (Colors.transparent, const Color(0xFF1F2421), null);
    }
  }
}
