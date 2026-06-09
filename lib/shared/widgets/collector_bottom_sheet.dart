import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
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
    final isNew    = rating == null || jobs == 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.sheetBR,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
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
              borderRadius: AppRadius.fullBR,
            ),
          ),
          const SizedBox(height: 24),

          // Avatar + name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initials,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.fullBR,
                            ),
                            child: Text(
                              'Online',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(20),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: Colors.blue.withAlpha(50)),
                              ),
                              child: Text(
                                'NEW',
                                style: AppTextStyles.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10),
                              ),
                            )
                          else ...[
                            ...List.generate(5, (i) => Icon(
                              i < rating.floor() 
                                  ? PhosphorIcons.star(PhosphorIconsStyle.fill) 
                                  : PhosphorIcons.star(PhosphorIconsStyle.regular),
                              color: AppColors.warning,
                              size: 14,
                            )),
                            const SizedBox(width: 6),
                            Text(
                              '${rating.toStringAsFixed(1)} ($jobs jobs)',
                              style: AppTextStyles.meta,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Vehicle + ETA chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (vehicle != null)
                  _InfoChip(icon: LucideIcons.truck, label: vehicle.replaceAll('_', ' ')),
                if (vehicle != null) const SizedBox(width: 10),
                const _InfoChip(
                  icon: LucideIcons.clock,
                  label: '~10-15 min',
                  color: AppColors.warning,
                ),
                if (plate != null) ...[
                  const SizedBox(width: 10),
                  _InfoChip(icon: LucideIcons.contact, label: plate),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (phone != null) launchUrl(Uri.parse('tel:$phone'));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
                    ),
                    child: const Icon(LucideIcons.phone, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onRequestPickup();
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 56)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.trash2, size: 20),
                        const SizedBox(width: 10),
                        Text('Book Pickup', style: AppTextStyles.button),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
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
    final c = color ?? AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
