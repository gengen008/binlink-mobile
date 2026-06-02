import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/booking_card.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('Earnings', style: AppTextStyles.h2),
            ),

            const SizedBox(height: 20),

            // Earnings summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _EarningsCard(
                    label: 'Today',
                    amount: prov.todayEarnings,
                    count: prov.todayPickups,
                    color: AppColors.steelBlue,
                  ),
                  const SizedBox(width: 12),
                  _EarningsCard(
                    label: 'Total',
                    amount: null,
                    count: prov.totalPickups,
                    color: AppColors.success,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _StatBox('${prov.todayPickups}', 'Today\'s\nPickups', AppColors.steelBlue),
                    _vDivider(),
                    _StatBox('${prov.totalPickups}', 'Total\nPickups', AppColors.skyBlue),
                    _vDivider(),
                    _StatBox(Fmt.currency(prov.todayEarnings), 'Today\'s\nEarnings', AppColors.success),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Recent Pickups', style: AppTextStyles.h4),
                  const Spacer(),
                  Text('${prov.completedPickups.length} total', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: prov.completedPickups.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.coins, color: AppColors.muted, size: 48),
                          SizedBox(height: 16),
                          Text('No pickups yet', style: AppTextStyles.h4),
                          SizedBox(height: 4),
                          Text('Go online and accept requests to earn', style: AppTextStyles.caption),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: prov.completedPickups.length,
                      itemBuilder: (_, i) => BookingCard(
                        booking: prov.completedPickups[i],
                        showCollector: false,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.label, this.amount, required this.count,
    required this.color, this.isTotal = false,
  });
  final String label;
  final double? amount;
  final int count;
  final Color color;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isTotal ? AppColors.cardGradient : null,
          color: isTotal ? null : color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: color)),
            const SizedBox(height: 8),
            if (amount != null)
              Text(Fmt.currency(amount!), style: AppTextStyles.monoLg.copyWith(color: AppColors.textPrimary))
            else
              Text('$count pickups', style: AppTextStyles.monoLg),
            if (amount != null) ...[
              const SizedBox(height: 2),
              Text('$count pickups', style: AppTextStyles.monoSm),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _StatBox(String value, String label, Color color) {
  return Expanded(
    child: Column(
      children: [
        Text(value, style: AppTextStyles.mono.copyWith(color: color, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    ),
  );
}

Widget _vDivider() => Container(width: 1, height: 40, color: AppColors.border);
