import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_bar.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<CollectorProvider>();
      prov.loadDashboard();
      prov.loadWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppScaffoldBar(
        title: 'Earnings',
        showBack: false,
        trailing: IconButton(
          onPressed: () { prov.loadDashboard(); prov.loadWallet(); },
          icon: const Icon(PhosphorIconsRegular.arrowClockwise),
        ),
      ),
      body: prov.loadingWallet
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async { prov.loadDashboard(); prov.loadWallet(); },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Wallet Balance ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: AppRadius.mdBR,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Balance', style: AppTextStyles.meta.copyWith(color: Colors.white.withAlpha(160))),
                        const SizedBox(height: 8),
                        Text(Fmt.currency(prov.walletAvailable), style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 32)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(label: 'Pending', value: Fmt.currency(prov.walletPending), color: AppColors.warning),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStat(label: 'Withdrawn', value: Fmt.currency(prov.walletWithdrawn), color: Colors.white.withAlpha(160)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Request Payout',
                          onPressed: prov.walletAvailable > 0 ? () => _showPayoutSheet(context, prov) : null,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Earnings are total amount minus 10% platform fee',
                            style: AppTextStyles.caption.copyWith(color: Colors.white.withAlpha(100), fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Recent Transactions ──────────────────────────────────────
                  Text('Recent Transactions', style: AppTextStyles.section),
                  const SizedBox(height: 16),
                  if (prov.walletTransactions.isEmpty)
                    const _EmptyState(asset: AppAssets.emptyEarnings, label: 'No transactions yet')
                  else
                    ...prov.walletTransactions.map((tx) => _TransactionTile(tx: tx)),
                  
                  const SizedBox(height: 32),
                  
                  // ── Completed Pickups ────────────────────────────────────────
                  Text('Completed Pickups', style: AppTextStyles.section),
                  const SizedBox(height: 16),
                  if (prov.completedPickups.isEmpty)
                    const _EmptyState(asset: AppAssets.emptyPickups, label: 'No completed pickups')
                  else
                    ...prov.completedPickups.map((b) => _PickupEarningTile(booking: b)),
                ],
              ),
            ),
    );
  }

  void _showPayoutSheet(BuildContext context, CollectorProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PayoutSheet(
        available: prov.walletAvailable,
        onSubmit: (phone, amt) => prov.requestPayout(phone, amt),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white.withAlpha(120), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final isPayout = tx['type'] == 'PAYOUT';
    final amount = Fmt.toDouble(tx['amount']);
    final date = tx['date'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isPayout ? PhosphorIconsRegular.arrowUpRight : PhosphorIconsRegular.arrowDownLeft,
            color: isPayout ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPayout ? 'Payout' : 'Pickup Earning', style: AppTextStyles.bodyMedium),
                if (date != null) Text(Fmt.shortDate(date), style: AppTextStyles.meta),
              ],
            ),
          ),
          Text(
            '${isPayout ? "-" : "+"}${Fmt.currency(amount)}',
            style: AppTextStyles.mono.copyWith(
              fontWeight: FontWeight.w700,
              color: isPayout ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupEarningTile extends StatelessWidget {
  const _PickupEarningTile({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final amount = Fmt.toDouble(booking['totalAmount']) * 0.9;
    final address = booking['pickupAddress'] as String? ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.truck, color: AppColors.textMuted),
          const SizedBox(width: 16),
          Expanded(
            child: Text(address, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Text(Fmt.currency(amount), style: AppTextStyles.mono.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.asset, required this.label});
  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadius.mdBR, border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          SvgPicture.asset(asset, height: 80),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.meta),
        ],
      ),
    );
  }
}

class _PayoutSheet extends StatefulWidget {
  const _PayoutSheet({required this.available, required this.onSubmit});
  final double available;
  final Future<bool> Function(String, double) onSubmit;

  @override
  State<_PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  final _numberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Request Payout', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          AppTextField(controller: _numberCtrl, label: 'MoMo Number', hint: '05XXXXXXX', keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          AppTextField(controller: _amountCtrl, label: 'Amount', hint: 'Max ${widget.available}', keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          AppButton(
            label: 'Submit Request',
            loading: _loading,
            onPressed: () async {
              final amt = double.tryParse(_amountCtrl.text) ?? 0;
              if (amt <= 0 || amt > widget.available) return;
              setState(() => _loading = true);
              final ok = await widget.onSubmit(_numberCtrl.text, amt);
              if (!context.mounted) return;
              setState(() => _loading = false);
              if (ok) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
