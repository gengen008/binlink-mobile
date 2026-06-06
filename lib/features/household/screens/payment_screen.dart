import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/l10n/strings.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import 'tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _confirmed = false; // true → show success screen

  late final AnimationController _successAnim;
  late final Animation<double> _scalePop;
  late final Animation<double> _fadePop;

  String get _paymentMethod =>
      widget.booking['paymentMethod'] as String? ?? 'CASH';

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scalePop = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut),
    );
    _fadePop = CurvedAnimation(parent: _successAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _successAnim.dispose();
    super.dispose();
  }

  void _showSuccess() {
    setState(() => _confirmed = true);
    _successAnim.forward();
  }

  void _trackPickup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrackingScreen(bookingId: widget.booking['id'] as String),
      ),
    );
  }

  void _backToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/household', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: _confirmed ? _buildSuccess() : _buildPaymentForm(),
      ),
    );
  }

  // ── Payment form ───────────────────────────────────────────────────────────

  Widget _buildPaymentForm() {
    final amount = Fmt.toDouble(widget.booking['totalAmount']);

    return SizedBox.expand(
      key: const ValueKey('form'),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppScaffoldBar(title: S.of(context).payment),
        body: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdBR,
                  color: AppColors.secondary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Amount Due',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Fmt.currency(amount),
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Payment method section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: AppTextStyles.section,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.mdBR,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsFill.money,
                            color: AppColors.primary, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Pay with Cash',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cash instruction
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.mdBR,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Have ${Fmt.currency(amount)} ready to pay your collector on arrival.',
                            style: AppTextStyles.meta,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  AppButton(
                    label: S.of(context).confirmBooking,
                    onPressed: _showSuccess,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success screen ─────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final bookingId = widget.booking['id'] as String? ?? '';
    final amount    =
        Fmt.toDouble(widget.booking['totalAmount']);
    final ref       = bookingId.length > 8
        ? bookingId.substring(0, 8).toUpperCase()
        : bookingId.toUpperCase();
    final isNow     = (widget.booking['scheduledDate'] as String?) == null;

    return SizedBox.expand(
      key: const ValueKey('success'),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppScaffoldBar(title: S.of(context).pickupConfirmed),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                const Spacer(),

                // Animated check circle
                ScaleTransition(
                  scale: _scalePop,
                  child: FadeTransition(
                    opacity: _fadePop,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(20),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIconsFill.checkCircle,
                          color: AppColors.primary,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                FadeTransition(
                  opacity: _fadePop,
                  child: Column(
                    children: [
                      Text(S.of(context).pickupConfirmed,
                          style: AppTextStyles.title,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        isNow
                            ? 'A collector is being assigned.\nExpected arrival: ~15 minutes.'
                            : 'Your scheduled pickup has been confirmed.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Booking reference card
                FadeTransition(
                  opacity: _fadePop,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.mdBR,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SuccessRow(label: S.of(context).bookingRef, value: '#$ref', isBold: true),
                        const Divider(height: 32),
                        _SuccessRow(label: S.of(context).amountPaid, value: Fmt.currency(amount)),
                        const SizedBox(height: 12),
                        _SuccessRow(label: 'Payment', value: Fmt.paymentMethodLabel(_paymentMethod)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Action buttons
                FadeTransition(
                  opacity: _fadePop,
                  child: Column(
                    children: [
                      AppButton(
                        label: S.of(context).trackPickup,
                        onPressed: _trackPickup,
                      ),

                      const SizedBox(height: 12),

                      // Download Receipt
                      OutlinedButton(
                        onPressed: () => ReceiptService.shareReceipt(widget.booking),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: Text(S.of(context).downloadReceipt),
                      ),

                      const SizedBox(height: 20),

                      // Back to Home
                      TextButton(
                        onPressed: _backToHome,
                        child: Text(
                          S.of(context).backToHome,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.meta),
        Text(value, style: isBold ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodyMedium),
      ],
    );
  }
}
