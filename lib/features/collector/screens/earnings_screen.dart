import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Earnings & Wallet', style: AppTextStyles.h2),
                        Text('Your financial overview', style: AppTextStyles.caption),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        prov.loadDashboard();
                        prov.loadWallet();
                      },
                      child: const Icon(PhosphorIconsRegular.arrowClockwise,
                          color: AppColors.skyBlue, size: 22),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: prov.loading && prov.loadingWallet
                    ? const Center(child: CircularProgressIndicator(
                        color: AppColors.steelBlue, strokeWidth: 2))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        children: [
                          // ── Wallet balance card ──
                          _WalletCard(
                            available:  prov.walletAvailable,
                            pending:    prov.walletPending,
                            withdrawn:  prov.walletWithdrawn,
                            onPayout:   () => _showPayoutSheet(context, prov),
                          ),

                          const SizedBox(height: 20),

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
                                borderRadius: BorderRadius.circular(20),
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

// ── Wallet balance card ────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.available,
    required this.pending,
    required this.withdrawn,
    required this.onPayout,
  });
  final double available;
  final double pending;
  final double withdrawn;
  final VoidCallback onPayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.steelBlue.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: AppColors.steelBlue.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: const Icon(PhosphorIconsFill.wallet,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Balance', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(Fmt.currency(available),
                      style: AppTextStyles.monoLg.copyWith(
                        color: AppColors.success,
                        fontSize: 28,
                      )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),

          Row(
            children: [
              _WalletStat('Pending', pending, AppColors.warning),
              const _VDiv(),
              _WalletStat('Withdrawn', withdrawn, AppColors.skyBlue),
            ],
          ),

          const SizedBox(height: 20),

          // Payout button
          GestureDetector(
            onTap: available > 0 ? onPayout : null,
            child: Opacity(
              opacity: available > 0 ? 1.0 : 0.45,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: available > 0 ? [
                    BoxShadow(
                      color: AppColors.steelBlue.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsFill.arrowCircleRight,
                        color: AppColors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Request Payout', style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletStat extends StatelessWidget {
  const _WalletStat(this.label, this.amount, this.color);
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(Fmt.currency(amount),
              style: AppTextStyles.mono.copyWith(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  const _VDiv();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        borderRadius: BorderRadius.circular(20),
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
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final date   = tx['date'] as String?;
    final isPayout = type == 'PAYOUT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
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
    final amount  = (booking['totalAmount'] as num?)?.toDouble() ?? 0;
    final address = booking['pickupAddress'] as String? ?? '';
    final date    = booking['createdAt'] as String?;
    final earned  = amount * 0.9; // platform takes 10%

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(2),
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
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.steelBlue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  );
}
