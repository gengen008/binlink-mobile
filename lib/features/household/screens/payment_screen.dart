import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/l10n/strings.dart';
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
      backgroundColor: AppColors.midnightNavy,
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
    final amount =
        Fmt.toDouble(widget.booking['totalAmount']);

    return SizedBox.expand(
      key: const ValueKey('form'),
      child: Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: AppColors.white),
                  ),
                  Expanded(
                      child: Text(S.of(context).payment, style: AppTextStyles.h3)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Amount display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Icon(PhosphorIconsFill.wallet,
                              color: AppColors.white, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            Fmt.currency(amount),
                            style: AppTextStyles.monoLg.copyWith(
                                fontSize: 32, color: AppColors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'via ${Fmt.paymentMethodLabel(_paymentMethod)}',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.iceBlue),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.success.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsFill.money,
                              color: AppColors.success, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.of(context).payInCash,
                                    style: AppTextStyles.h4
                                        .copyWith(color: AppColors.success)),
                                const SizedBox(height: 4),
                                Text(
                                  'Have ${Fmt.currency(amount)} ready to pay your collector on arrival.',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: S.of(context).confirmBooking,
                      onPressed: _showSuccess,
                      icon: const Icon(PhosphorIconsRegular.checkCircle,
                          color: AppColors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
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
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.midnightNavy, AppColors.deepOcean],
        ),
      ),
      child: SafeArea(
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
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withAlpha(20),
                      border: Border.all(
                          color: AppColors.success.withAlpha(80), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withAlpha(60),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      PhosphorIconsFill.checkCircle,
                      color: AppColors.success,
                      size: 60,
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
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.white,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      isNow
                          ? 'A collector is being assigned.\nExpected arrival: ~15 minutes.'
                          : 'Your scheduled pickup has been confirmed.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Booking reference card
              FadeTransition(
                opacity: _fadePop,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(S.of(context).bookingRef,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.muted)),
                          Text(
                            '#$ref',
                            style: AppTextStyles.mono.copyWith(
                              color: AppColors.iceBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(S.of(context).amountPaid,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.muted)),
                          Text(
                            Fmt.currency(amount),
                            style: AppTextStyles.monoLg.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.muted)),
                          Text(
                            Fmt.paymentMethodLabel(_paymentMethod),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
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
                      icon: const Icon(PhosphorIconsRegular.mapPin,
                          color: AppColors.white, size: 20),
                    ),

                    const SizedBox(height: 12),

                    // Download Receipt
                    GestureDetector(
                      onTap: () => ReceiptService.shareReceipt(widget.booking),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(PhosphorIconsRegular.downloadSimple,
                                color: AppColors.skyBlue, size: 18),
                            const SizedBox(width: 8),
                            Text(S.of(context).downloadReceipt,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.skyBlue,
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back to Home
                    GestureDetector(
                      onTap: _backToHome,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          S.of(context).backToHome,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.muted,
                          ),
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
    ));
  }
}
