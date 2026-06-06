import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar.dart';
import '../providers/household_provider.dart';

/// Subscriptions / Payments & Plans screen.
///
/// Shows the user's active subscription plan and allows cancellation.
/// Wired to: GET /api/subscriptions/mine (via HouseholdProvider.subscriptions)
///           DELETE /api/subscriptions/:id (via HouseholdProvider.cancelSubscription)
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().loadSubscriptions();
    });
  }

  Future<void> _cancelSub(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        title: Text('Cancel Plan', style: AppTextStyles.h4),
        content: Text(
          'Are you sure you want to cancel your subscription? You can still book one-off pickups.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Plan',
                style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel Plan',
                style: AppTextStyles.label.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<HouseholdProvider>().cancelSubscription(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription cancelled'),
        backgroundColor: AppColors.steelBlue,
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
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(title: 'Payments & Plans'),
      body: prov.loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.steelBlue, strokeWidth: 2),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info banner ──────────────────────────────────────
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: _InfoBanner(),
                    ),

                    const SizedBox(height: 24),

                    // ── Section heading ──────────────────────────────────
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 100),
                      child: Text('Active Plans',
                          style: AppTextStyles.h4.copyWith(
                              color: AppColors.skyBlue)),
                    ),
                    const SizedBox(height: 12),

                    if (activeSubs.isEmpty) ...[
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        child: _EmptyPlans(),
                      ),
                    ] else ...[
                      ...activeSubs.asMap().entries.map((e) {
                        final delay =
                            Duration(milliseconds: 200 + e.key * 80);
                        return FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          delay: delay,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SubCard(
                              sub: e.value,
                              onCancel: () =>
                                  _cancelSub(e.value['id'] as String),
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 32),

                    // ── Pricing info ─────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 300),
                      child: _PricingCard(),
                    ),
                  ],
                ),
              ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withAlpha(15),
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.steelBlue.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.info,
              color: AppColors.steelBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'BinLink uses cash-on-delivery only. Pay your collector directly upon arrival.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPlans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(PhosphorIconsRegular.calendarBlank,
              color: AppColors.muted, size: 40),
          const SizedBox(height: 12),
          Text('No active plans',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            'Book a recurring pickup from the home screen\nto start a subscription plan.',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────────

class _SubCard extends StatelessWidget {
  const _SubCard({required this.sub, required this.onCancel});
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaused ? AppColors.card : AppColors.cardElevated,
        borderRadius: AppRadius.mdBR,
        border: Border.all(
          color: isPaused
              ? AppColors.border
              : AppColors.steelBlue.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withAlpha(20),
                  borderRadius: AppRadius.smBR,
                  border: Border.all(color: AppColors.steelBlue.withAlpha(50)),
                ),
                child: const Icon(PhosphorIconsFill.recycle,
                    color: AppColors.steelBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_freqLabel(frequency)} Pickup',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      '${Fmt.binSizeLabel(binSize)} • ${Fmt.currency(amount)}',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaused
                      ? AppColors.warning.withAlpha(20)
                      : AppColors.success.withAlpha(20),
                  borderRadius: AppRadius.fullBR,
                  border: Border.all(
                    color: isPaused
                        ? AppColors.warning.withAlpha(60)
                        : AppColors.success.withAlpha(60),
                  ),
                ),
                child: Text(
                  isPaused ? 'Paused' : 'Active',
                  style: AppTextStyles.chip.copyWith(
                    color: isPaused ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          if (nextDt != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.calendar,
                    color: AppColors.muted, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Next pickup: ${Fmt.date(nextDt)}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),

          // Cancel button
          GestureDetector(
            onTap: onCancel,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsRegular.x,
                    color: AppColors.danger, size: 14),
                const SizedBox(width: 6),
                Text('Cancel Plan',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger)),
              ],
            ),
          ),
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

// ── Pricing reference card ────────────────────────────────────────────────────

class _PricingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.wallet,
                  color: AppColors.skyBlue, size: 18),
              const SizedBox(width: 8),
              Text('Pickup Pricing', style: AppTextStyles.h4),
            ],
          ),
          const SizedBox(height: 16),
          const _PriceRow(label: 'Small (≤120L)',  price: 'GHC 30'),
          const _PriceRow(label: 'Medium (180L)',  price: 'GHC 40'),
          const _PriceRow(label: 'Large (240L)',   price: 'GHC 50'),
          const _PriceRow(label: 'Extra bag',      price: 'GHC 6'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.coinVertical,
                  color: AppColors.muted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cash on delivery only. Pay your collector directly.',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.price});
  final String label;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          Text(price,
              style: AppTextStyles.mono.copyWith(color: AppColors.iceBlue)),
        ],
      ),
    );
  }
}
