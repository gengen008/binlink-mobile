import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_assets.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(_getCategoryAsset(category), fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: AppTextStyles.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Fmt.categoryLabel(category ?? '')} · ${createdAt != null ? Fmt.shortDate(createdAt) : '—'}',
                      style: AppTextStyles.label,
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
                    style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  _StatusPill(status: status, color: statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryAsset(String? category) {
    switch (category) {
      case 'PLASTIC': return AppAssets.recycleBin;
      case 'ORGANIC': return AppAssets.leaf;
      case 'CONSTRUCTION': return AppAssets.truck3d;
      default: return AppAssets.bin3d;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        Fmt.statusLabel(status).toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
