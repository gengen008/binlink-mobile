import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NavigationOverlay extends StatelessWidget {
  const NavigationOverlay({
    super.key,
    required this.instructionText,
    required this.distanceMeters,
    required this.maneuver,
    required this.etaMinutes,
    required this.distanceKm,
    required this.speedLimitKph,
    required this.currentSpeedKph,
  });

  final String instructionText;
  final int distanceMeters;
  final String maneuver; // 'left', 'right', 'straight', 'uturn'
  final int etaMinutes;
  final double distanceKm;
  final int speedLimitKph;
  final double currentSpeedKph;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Top Banner: Turn Instruction ──
        Positioned(
          top: MediaQuery.paddingOf(context).top + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(_getManeuverIcon(maneuver), color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${distanceMeters >= 1000 ? (distanceMeters / 1000).toStringAsFixed(1) + ' km' : '$distanceMeters m'}',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      Text(
                        instructionText,
                        style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Speed Limit Badge ──
        Positioned(
          top: MediaQuery.paddingOf(context).top + 110,
          right: 16,
          child: _SpeedBadge(
            limit: speedLimitKph,
            currentSpeed: currentSpeedKph,
          ),
        ),

        // ── Lane Guidance (Fake implementation for design) ──
        Positioned(
          top: MediaQuery.paddingOf(context).top + 110,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _LaneIcon(icon: LucideIcons.cornerLeftUp, isActive: false),
                const SizedBox(width: 8),
                _LaneIcon(icon: LucideIcons.arrowUp, isActive: true),
                const SizedBox(width: 8),
                _LaneIcon(icon: LucideIcons.arrowUp, isActive: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getManeuverIcon(String m) {
    switch (m.toLowerCase()) {
      case 'left': return LucideIcons.cornerLeftUp;
      case 'right': return LucideIcons.cornerRightUp;
      case 'uturn': return LucideIcons.rotateCcw;
      default: return LucideIcons.arrowUp;
    }
  }
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge({required this.limit, required this.currentSpeed});
  final int limit;
  final double currentSpeed;

  @override
  Widget build(BuildContext context) {
    final isOverLimit = currentSpeed > limit + 5;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOverLimit ? AppColors.danger : Colors.white,
        border: Border.all(color: isOverLimit ? Colors.white : AppColors.danger, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          '$limit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isOverLimit ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _LaneIcon extends StatelessWidget {
  const _LaneIcon({required this.icon, required this.isActive});
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: isActive ? Colors.white : Colors.white38,
      size: 20,
    );
  }
}
