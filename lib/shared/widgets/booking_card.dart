import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/formatters.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  final Map<String, dynamic> booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'PENDING';
    final address = booking['pickupAddress'] as String? ?? '—';
    final amount = Fmt.toDouble(booking['totalAmount']);
    final createdAt = booking['createdAt'] as String?;
    final category = booking['wasteCategory'] as String?;
    final statusColor = AppColors.statusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBR,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.mdBR,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.smBR,
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Fmt.categoryLabel(category ?? '')} · ${createdAt != null ? Fmt.shortDate(createdAt) : '—'}',
                      style: AppTextStyles.meta,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.currency(amount),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  _StatusPill(status: status, color: statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'PLASTIC': return PhosphorIconsFill.recycle;
      case 'ORGANIC': return PhosphorIconsFill.leaf;
      case 'EWASTE': return PhosphorIconsFill.laptop;
      default: return PhosphorIconsFill.trashSimple;
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: AppRadius.xsBR,
      ),
      child: Text(
        Fmt.statusLabel(status),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
