import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../providers/household_provider.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/stats_row.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final bookings = prov.bookings;

    // PASS 3: Compute stats from bookings
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
                ...bookings.map((b) => BookingCard(booking: b)),
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
