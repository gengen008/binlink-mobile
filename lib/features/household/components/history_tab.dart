import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../providers/household_provider.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/skeleton.dart';

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

    final completed = bookings.where((b) => b['status'] == 'COMPLETED').toList();
    final totalSpent = completed.fold(0.0, (sum, b) => sum + Fmt.toDouble(b['totalAmount']));
    final totalKg = completed.fold(0.0, (sum, b) => sum + Fmt.toDouble(b['actualWeightKg']));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(
        title: 'Pickup History',
        showBack: false,
      ),
      body: prov.loading
        ? const SkeletonList(itemCount: 8, itemHeight: 120)
        : bookings.isEmpty
          ? const _EmptyHistory()
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                // ── Summary Header ──
                FadeInDown(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _HeaderStat(label: 'Pickups', value: '${completed.length}'),
                            _HeaderStat(label: 'Total Spent', value: Fmt.currency(totalSpent)),
                            _HeaderStat(label: 'Weight', value: '${totalKg.toInt()} kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text("Recent Bookings", style: AppTextStyles.h3),
                ),

                ...completed.map((b) => FadeInUp(
                  child: BookingCard(
                    booking: b,
                    onTap: () => _showDetailSheet(context, b),
                  ),
                )),
              ],
            ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

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
    final actualKg    = Fmt.toDouble(booking['actualWeightKg']);
    final statusColor = AppColors.statusColor(status);

    final collectorObj  = booking['collector'] as Map<String, dynamic>?;
    final collectorName = collectorObj?['fullName'] as String? ?? '—';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booking Detail', style: AppTextStyles.h2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(16)),
                    child: Text(Fmt.statusLabel(status), style: AppTextStyles.small.copyWith(color: statusColor, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  if (status == 'COMPLETED')
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading receipt...'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withAlpha(10), shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withAlpha(20))),
                        child: Icon(LucideIcons.download, size: 20, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          _InfoRow(icon: LucideIcons.mapPin, label: 'Address', value: address),
          _InfoRow(icon: LucideIcons.trash2, label: 'Category', value: Fmt.categoryLabel(category ?? '')),
          if (binSize != null) _InfoRow(icon: LucideIcons.package, label: 'Bin Size', value: binSize),
          _InfoRow(icon: LucideIcons.calendar, label: 'Date', value: createdAt != null ? Fmt.shortDate(createdAt) : '—'),
          if (actualKg > 0) _InfoRow(icon: LucideIcons.scale, label: 'Actual Weight', value: '${actualKg.toStringAsFixed(1)} kg'),
          _InfoRow(icon: LucideIcons.user, label: 'Collector', value: collectorName),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: AppTextStyles.h3),
              Text(Fmt.currency(amount), style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              Text(value, style: AppTextStyles.h4),
            ],
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
          SvgPicture.asset(AppAssets.emptyPickups, height: 120),
          const SizedBox(height: 32),
          Text('No pickups yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Your clean history starts here.', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
