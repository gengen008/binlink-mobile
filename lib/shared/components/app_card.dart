import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_motion.dart';
import '../../app.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.edgeMD,
    this.color,
    this.border,
    this.hasShadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final BorderSide? border;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.binlinkColors;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? colors.surface,
          borderRadius: AppRadius.lgBR,
          border: border != null ? Border.fromBorderSide(border!) : Border.all(color: colors.border, width: 0.5),
          boxShadow: hasShadow
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: child,
      ).animate(target: onTap != null ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(0.98, 0.98), duration: AppMotion.fast),
    );
  }
}
