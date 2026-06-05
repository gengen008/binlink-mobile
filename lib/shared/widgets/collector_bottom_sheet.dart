import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Modal bottom sheet shown when a collector pin is tapped on the household map.
void showCollectorSheet(
  BuildContext context,
  Map<String, dynamic> collector, {
  required VoidCallback onRequestPickup,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CollectorSheet(
      collector: collector,
      onRequestPickup: onRequestPickup,
    ),
  );
}

class _CollectorSheet extends StatelessWidget {
  const _CollectorSheet({
    required this.collector,
    required this.onRequestPickup,
  });

  final Map<String, dynamic> collector;
  final VoidCallback onRequestPickup;

  @override
  Widget build(BuildContext context) {
    final name     = collector['fullName'] as String? ?? 'Collector';
    final phone    = collector['phone'] as String?;
    final rating   = (collector['rating'] as num?)?.toDouble();
    final jobs     = (collector['totalPickups'] as num?)?.toInt() ?? 0;
    final vehicle  = collector['vehicleType'] as String?;
    final plate    = collector['vehiclePlate'] as String?;
    final initials = Fmt.initials(name);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar + name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Name, rating, online badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.h3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success.withAlpha(80)),
                            ),
                            child: Text(
                              'Online',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Stars + job count
                      if (rating != null && rating > 0) ...[
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < rating.floor()
                                  ? PhosphorIconsFill.star
                                  : (i < rating
                                      ? PhosphorIconsFill.starHalf
                                      : PhosphorIconsRegular.star),
                              color: AppColors.warning,
                              size: 14,
                            )),
                            const SizedBox(width: 6),
                            Text(
                              '${rating.toStringAsFixed(1)} ($jobs jobs)',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'New Collector',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.skyBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Vehicle + ETA chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (vehicle != null)
                  _InfoChip(
                    icon: PhosphorIconsRegular.truck,
                    label: vehicle.replaceAll('_', ' '),
                  ),
                if (vehicle != null) const SizedBox(width: 10),
                const _InfoChip(
                  icon: PhosphorIconsRegular.clock,
                  label: '~10-15 min',
                  color: AppColors.warning,
                ),
                if (plate != null) ...[
                  const SizedBox(width: 10),
                  _InfoChip(
                    icon: PhosphorIconsRegular.identificationCard,
                    label: plate,
                    color: AppColors.skyBlue,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.border, height: 1),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(
              children: [
                // Call button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (phone != null) {
                        launchUrl(Uri.parse('tel:$phone'));
                      }
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsRegular.phone,
                              color: AppColors.skyBlue, size: 18),
                          const SizedBox(width: 8),
                          Text('Call',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.skyBlue,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Request pickup
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onRequestPickup();
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsFill.trashSimple,
                              color: AppColors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Request Pickup',
                              style: AppTextStyles.button),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 13),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption.copyWith(color: c, fontSize: 11)),
        ],
      ),
    );
  }
}
