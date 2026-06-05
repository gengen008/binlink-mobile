import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';

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
    return Consumer<CollectorProvider>(
      builder: (_, prov, __) => Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // ── Branded balance banner ─────────────────────────────────
            _EarningsBanner(
              available:  prov.walletAvailable,
              pending:    prov.walletPending,
              withdrawn:  prov.walletWithdrawn,
              loading:    prov.loading || prov.loadingWallet,
              onRefresh:  () { prov.loadDashboard(); prov.loadWallet(); },
              onPayout:   () => _showPayoutSheet(context, prov),
            ),

            Expanded(
              child: prov.loading && prov.loadingWallet
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.steelBlue, strokeWidth: 2))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      children: [
                          // ── Today summary ──
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  label: "Today's Earnings",
                                  value: Fmt.currency(prov.todayEarnings),
                                  sub: '${prov.todayPickups} pickups',
                                  color: AppColors.steelBlue,
                                  icon: PhosphorIconsFill.coins,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryCard(
                                  label: 'Total Pickups',
                                  value: '${prov.totalPickups}',
                                  sub: 'all time',
                                  color: AppColors.success,
                                  icon: PhosphorIconsFill.truck,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Transaction history ──
                          Row(
                            children: [
                              const Text('Transaction History', style: AppTextStyles.h4),
                              const Spacer(),
                              Text('${prov.walletTransactions.length} entries',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (prov.walletTransactions.isEmpty)
                            _EmptyTransactions()
                          else
                            ...prov.walletTransactions.map(
                              (tx) => _TransactionTile(tx: tx)),

                          const SizedBox(height: 20),

                          // ── Completed pickups ──
                          Row(
                            children: [
                              const Text('Completed Pickups', style: AppTextStyles.h4),
                              const Spacer(),
                              Text('${prov.completedPickups.length} total',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (prov.completedPickups.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.sheet),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Column(
                                children: [
                                  Icon(PhosphorIconsRegular.coins,
                                      color: AppColors.muted, size: 40),
                                  SizedBox(height: 12),
                                  Text('No pickups yet',
                                      style: AppTextStyles.h4),
                                  SizedBox(height: 4),
                                  Text('Go online and accept requests to earn',
                                      style: AppTextStyles.caption,
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            )
                          else
                            ...prov.completedPickups.map(
                              (b) => _PickupEarningTile(booking: b)),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutSheet(BuildContext ctx, CollectorProvider prov) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PayoutSheet(
        available: prov.walletAvailable,
        onSubmit: (number, amount) => prov.requestPayout(number, amount),
      ),
    );
  }
}

// ── Branded earnings banner ────────────────────────────────────────────────

class _EarningsBanner extends StatelessWidget {
  const _EarningsBanner({
    required this.available,
    required this.pending,
    required this.withdrawn,
    required this.loading,
    required this.onRefresh,
    required this.onPayout,
  });
  final double available;
  final double pending;
  final double withdrawn;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onPayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF052659), Color(0xFF0A2D5A)],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.steelBlue.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.skyBlue.withAlpha(12),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.steelBlue.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsFill.wallet,
                                color: AppColors.steelBlue, size: 12),
                            const SizedBox(width: 5),
                            Text('Wallet',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.steelBlue,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRefresh,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.steelBlue.withAlpha(25),
                            borderRadius: AppRadius.smBR,
                            border: Border.all(
                                color: AppColors.steelBlue.withAlpha(60)),
                          ),
                          child: loading
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.steelBlue),
                                )
                              : const Icon(PhosphorIconsRegular.arrowClockwise,
                                  color: AppColors.steelBlue, size: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Balance
                  Text('Available Balance',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.skyBlue, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    Fmt.currency(available),
                    style: AppTextStyles.monoLg.copyWith(
                        fontSize: 34, letterSpacing: -0.5),
                  ),

                  const SizedBox(height: 14),

                  // Pending + Withdrawn chips
                  Row(
                    children: [
                      _BannerStat(
                          label: 'Pending',
                          value: Fmt.currency(pending),
                          color: AppColors.warning),
                      const SizedBox(width: 10),
                      _BannerStat(
                          label: 'Withdrawn',
                          value: Fmt.currency(withdrawn),
                          color: AppColors.skyBlue),
                      const Spacer(),

                      // Payout CTA button
                      GestureDetector(
                        onTap: available > 0 ? onPayout : null,
                        child: Opacity(
                          opacity: available > 0 ? 1.0 : 0.4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: available > 0
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.steelBlue.withAlpha(80),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIconsFill.arrowCircleRight,
                                    color: AppColors.white, size: 14),
                                SizedBox(width: 6),
                                Text('Payout',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      color: AppColors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _BannerStat extends StatelessWidget {
  const _BannerStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontSize: 9)),
          Text(value,
              style: AppTextStyles.monoSm
                  .copyWith(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Summary card ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.mono.copyWith(
            color: AppColors.textPrimary, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          Text(sub, style: AppTextStyles.caption.copyWith(
            color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Transaction tile ───────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final type   = tx['type'] as String? ?? 'EARNING';
    final amount = Fmt.toDouble(tx['amount']);
    final date   = tx['date'] as String?;
    final isPayout = type == 'PAYOUT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isPayout ? AppColors.warning : AppColors.success).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPayout ? PhosphorIconsFill.arrowCircleRight : PhosphorIconsFill.coins,
              color: isPayout ? AppColors.warning : AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPayout ? 'Payout' : 'Pickup Earned',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                if (date != null)
                  Text(Fmt.shortDate(date), style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(
            '${isPayout ? '-' : '+'}${Fmt.currency(amount)}',
            style: AppTextStyles.mono.copyWith(
              color: isPayout ? AppColors.warning : AppColors.success,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(PhosphorIconsRegular.receipt, color: AppColors.muted, size: 22),
          SizedBox(width: 12),
          Text('No transactions yet', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Pickup earning tile ────────────────────────────────────────────────────

class _PickupEarningTile extends StatelessWidget {
  const _PickupEarningTile({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final amount  = Fmt.toDouble(booking['totalAmount']);
    final address = booking['pickupAddress'] as String? ?? '';
    final date    = booking['createdAt'] as String?;
    final earned  = amount * 0.9; // platform takes 10%

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.trashSimple,
              color: AppColors.steelBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (date != null)
                  Text(Fmt.shortDate(date),
                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(Fmt.currency(earned),
              style: AppTextStyles.mono.copyWith(
                color: AppColors.success, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Payout sheet ───────────────────────────────────────────────────────────

class _PayoutSheet extends StatefulWidget {
  const _PayoutSheet({required this.available, required this.onSubmit});
  final double available;
  final Future<bool> Function(String momoNumber, double amount) onSubmit;

  @override
  State<_PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  final _phoneCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool _submitting  = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(_phoneCtrl.text.trim(), amount);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payout request submitted!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payout failed. Try again.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepOcean,
        borderRadius: AppRadius.sheetBR,
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.fullBR,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success.withAlpha(80)),
                  ),
                  child: const Icon(PhosphorIconsFill.wallet,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Request Payout', style: AppTextStyles.h3),
                    Text(
                      'Available: ${Fmt.currency(widget.available)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text('MoMo Number', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodyMedium,
              decoration: _inputDecoration('e.g. 0241234567'),
              validator: (v) {
                if (v == null || v.length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),

            const SizedBox(height: 16),

            const Text('Amount (GHC)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.textPrimary, fontSize: 16),
              decoration: _inputDecoration('e.g. 50.00'),
              validator: (v) {
                final amt = double.tryParse(v?.trim() ?? '');
                if (amt == null || amt <= 0) return 'Enter a valid amount';
                if (amt > widget.available) return 'Exceeds available balance';
                return null;
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: AppColors.steelBlue.withAlpha(60),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitting ? null : _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.white),
                            )
                          : const Text('Confirm Payout', style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.caption,
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: AppRadius.lgBR,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.lgBR,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.lgBR,
      borderSide: const BorderSide(color: AppColors.steelBlue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.lgBR,
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.lgBR,
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  );
}
