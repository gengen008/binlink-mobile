import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import 'status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showCollector = false,
  });

  final Map<String, dynamic> booking;
  final VoidCallback? onTap;
  final bool showCollector;

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'PENDING';
    final binSize = booking['binSize'] as String? ?? '';
    final address = booking['pickupAddress'] as String? ?? '';
    final amount  = Fmt.toDouble(booking['totalAmount']);
    final createdAt = DateTime.tryParse(booking['createdAt'] as String? ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.steelBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    PhosphorIconsFill.trashSimple,
                    color: AppColors.steelBlue, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Fmt.binSizeLabel(binSize), style: AppTextStyles.h4),
                      const SizedBox(height: 2),
                      Text(
                        createdAt != null ? Fmt.dateTime(createdAt) : '',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status, animate: true),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                const Icon(PhosphorIconsRegular.mapPin, color: AppColors.skyBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (showCollector && booking['collector'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.user, color: AppColors.skyBlue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    booking['collector']['fullName'] as String? ?? 'Collector',
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Amount + arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Fmt.currency(amount), style: AppTextStyles.mono.copyWith(color: AppColors.iceBlue)),
                const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.muted, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
