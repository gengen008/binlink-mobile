import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.mono.copyWith(
                color: AppColors.secondary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
          icon: PhosphorIconsFill.trashSimple,
          label: 'Pickups',
          value: '$totalPickups',
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        StatChip(
          icon: PhosphorIconsFill.wallet,
          label: 'Total Spent',
          value: 'GHC ${totalSpent.toStringAsFixed(0)}',
          color: AppColors.muted,
        ),
        const SizedBox(width: 10),
        StatChip(
          icon: PhosphorIconsFill.leaf,
          label: 'kg Recycled',
          value: '${kgRecycled.toStringAsFixed(1)}kg',
          color: AppColors.success,
        ),
      ],
    );
  }
}
