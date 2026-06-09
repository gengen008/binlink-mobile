import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/skeleton.dart';
import '../providers/household_provider.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().loadSubscriptions();
    });
  }

  Future<void> _cancelSub(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel Plan', style: AppTextStyles.h3),
        content: Text(
          'Are you sure you want to cancel your subscription? You can still book one-off pickups anytime.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Plan', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel Plan', style: AppTextStyles.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<HouseholdProvider>().cancelSubscription(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Subscription cancelled'),
        backgroundColor: AppColors.primary900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final activeSubs = prov.subscriptions
        .where((s) => s['status'] != 'CANCELLED')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppScaffoldBar(title: 'Payments & Plans'),
      body: prov.loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonList(itemCount: 3, itemHeight: 180),
              )
            : RefreshIndicator(
                onRefresh: () => prov.loadSubscriptions(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Premium Info Header ──
                      FadeInDown(
                        child: _PremiumInfoCard(),
                      ),

                      const SizedBox(height: 32),

                      Text('ACTIVE PLANS', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      const SizedBox(height: 16),

                      if (activeSubs.isEmpty) ...[
                        FadeInUp(
                          child: _EmptyPlans(),
                        ),
                      ] else ...[
                        ...activeSubs.asMap().entries.map((e) {
                          return FadeInUp(
                            delay: Duration(milliseconds: e.key * 100),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _SubCardV4(
                                sub: e.value,
                                onCancel: () => _cancelSub(e.value['id'] as String),
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 32),
                      Text('PRICING REFERENCE', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: _PricingReference(),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _PremiumInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary900,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.primary900.withAlpha(30), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduled Pickups', style: AppTextStyles.title.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'Manage your recurring waste collection plans and billing here.',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Lottie.asset(AppAssets.lottieWallet, width: 60, height: 60),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Lottie.asset(AppAssets.lottieSearching, height: 120),
          const SizedBox(height: 24),
          Text('No active plans', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'You haven\'t subscribed to any recurring pickups yet.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SubCardV4 extends StatelessWidget {
  const _SubCardV4({required this.sub, required this.onCancel});
  final Map<String, dynamic> sub;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final frequency = sub['plan'] as String? ?? 'WEEKLY';
    final binSize   = sub['binSize']   as String? ?? 'MEDIUM';
    final amount    = Fmt.toDouble(sub['price']);
    final status    = sub['status']    as String? ?? 'ACTIVE';
    final nextDate  = sub['nextPickupDate'] as String?;
    final nextDt    = nextDate != null ? DateTime.tryParse(nextDate) : null;
    final isPaused  = status == 'PAUSED';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isPaused ? AppColors.warning : AppColors.success).withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.small.copyWith(
                    color: isPaused ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(LucideIcons.ellipsisVertical, size: 20, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${_freqLabel(frequency)} Pickup', style: AppTextStyles.h2.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            '${Fmt.binSizeLabel(binSize)} • ${Fmt.currency(amount)} per pickup',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          
          if (nextDt != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary900),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT PICKUP', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
                    Text(Fmt.date(nextDt), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _freqLabel(String f) {
    switch (f.toUpperCase()) {
      case 'DAILY':    return 'Daily';
      case 'WEEKLY':   return 'Weekly';
      case 'BIWEEKLY': return 'Bi-Weekly';
      case 'MONTHLY':  return 'Monthly';
      default:         return f;
    }
  }
}

class _PricingReference extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _priceItem('Small Bin (≤120L)', 'GHC 30'),
          const Divider(height: 32),
          _priceItem('Medium Bin (180L)', 'GHC 40'),
          const Divider(height: 32),
          _priceItem('Large Bin (240L)', 'GHC 50'),
          const Divider(height: 32),
          _priceItem('Extra Bag', 'GHC 6'),
        ],
      ),
    );
  }

  Widget _priceItem(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        Text(price, style: AppTextStyles.h3.copyWith(fontSize: 18, color: AppColors.primary900)),
      ],
    );
  }
}
