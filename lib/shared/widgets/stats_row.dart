import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_radius.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: AppRadius.smBR,
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.mono.copyWith(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.totalPickups,
    required this.totalSpent,
    required this.kgRecycled,
  });

  final int totalPickups;
  final double totalSpent;
  final double kgRecycled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatChip(
          icon: LucideIcons.trash2,
          label: 'Pickups',
          value: '$totalPickups',
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        StatChip(
          icon: LucideIcons.wallet,
          label: 'Spent',
          value: '₵${totalSpent.toStringAsFixed(0)}',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 8),
        StatChip(
          icon: LucideIcons.leaf,
          label: 'Recycled',
          value: '${kgRecycled.toInt()}kg',
          color: AppColors.success,
        ),
      ],
    );
  }
}
