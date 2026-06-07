import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../providers/household_provider.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/stats_row.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  void _showDetailSheet(BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final bookings = prov.bookings;

    // Compute stats from bookings
    final completed = bookings.where((b) => b['status'] == 'COMPLETED').toList();
    final totalSpent = completed.fold(0.0, (sum, b) => sum + Fmt.toDouble(b['totalAmount']));
    final totalKg = completed.fold(0.0, (sum, b) => sum + Fmt.toDouble(b['actualWeightKg']));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppScaffoldBar(
        title: 'Pickup History',
        showBack: false,
      ),
      body: prov.loading
        ? const Center(child: CircularProgressIndicator())
        : bookings.isEmpty
          ? const _EmptyHistory()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: StatsRow(
                    totalPickups: completed.length,
                    totalSpent: totalSpent,
                    kgRecycled: totalKg,
                  ),
                ),
                const SizedBox(height: 12),
                ...bookings.map((b) => BookingCard(
                  booking: b,
                  onTap: () => _showDetailSheet(context, b),
                )),
              ],
            ),
    );
  }
}

// ── Booking Detail Bottom Sheet ────────────────────────────────────────────────

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final status      = booking['status'] as String? ?? 'PENDING';
    final address     = booking['pickupAddress'] as String? ?? '—';
    final amount      = Fmt.toDouble(booking['totalAmount']);
    final category    = booking['wasteCategory'] as String?;
    final binSize     = booking['binSize'] as String?;
    final createdAt   = booking['createdAt'] as String?;
    final scheduled   = booking['scheduledDate'] as String?;
    final timePref    = booking['timePreference'] as String?;
    final actualKg    = Fmt.toDouble(booking['actualWeightKg']);
    final ref         = booking['id'] as String? ?? '';
    final statusColor = AppColors.statusColor(status);

    // Collector info — nested object
    final collectorObj  = booking['collector'] as Map<String, dynamic>?;
    final collectorName = collectorObj?['fullName'] as String? ?? '—';

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.sheetBR,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Text('Booking Detail', style: AppTextStyles.h3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: AppRadius.fullBR,
                        ),
                        child: Text(
                          Fmt.statusLabel(status),
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Booking ref
                  if (ref.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${ref.length > 12 ? ref.substring(0, 12).toUpperCase() : ref.toUpperCase()}',
                      style: AppTextStyles.meta.copyWith(fontFamily: 'DM Mono'),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Detail rows
                  _DetailRow(
                    icon: PhosphorIconsRegular.mapPin,
                    label: 'Pickup Address',
                    value: address,
                  ),
                  _DetailRow(
                    icon: PhosphorIconsRegular.trash,
                    label: 'Waste Category',
                    value: Fmt.categoryLabel(category ?? ''),
                  ),
                  if (binSize != null)
                    _DetailRow(
                      icon: PhosphorIconsRegular.package,
                      label: 'Bin Size',
                      value: binSize,
                    ),
                  _DetailRow(
                    icon: PhosphorIconsRegular.calendarBlank,
                    label: 'Booked On',
                    value: createdAt != null ? Fmt.shortDate(createdAt) : '—',
                  ),
                  if (scheduled != null)
                    _DetailRow(
                      icon: PhosphorIconsRegular.clock,
                      label: 'Scheduled',
                      value: '${Fmt.shortDate(scheduled)}${timePref != null ? ' · $timePref' : ''}',
                    ),
                  _DetailRow(
                    icon: PhosphorIconsRegular.user,
                    label: 'Collector',
                    value: collectorName,
                  ),
                  if (actualKg > 0)
                    _DetailRow(
                      icon: PhosphorIconsRegular.scales,
                      label: 'Actual Weight',
                      value: '${actualKg.toStringAsFixed(1)} kg',
                    ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Amount row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Paid', style: AppTextStyles.bodyMedium),
                      Text(
                        Fmt.currency(amount),
                        style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Download Receipt button
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generating receipt...')),
                      );
                    },
                    icon: const Icon(PhosphorIconsRegular.downloadSimple, size: 18),
                    label: const Text('Download Receipt'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.meta),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(AppAssets.emptyPickups, height: 100),
          const SizedBox(height: 24),
          Text('No history yet', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Your completed pickups will appear here.',
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }
}
