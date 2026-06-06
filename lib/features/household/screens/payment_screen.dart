import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 1800),
                    child: Container(
                      width: 340,
                      height: 122,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.secondary,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Amount Due',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF3F3C1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            Fmt.currency(amount),
                            style: AppTextStyles.h1.copyWith(
                              color: const Color(0xFFF3F3C1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Payment method section
            FadeInUp(
              duration: const Duration(milliseconds: 2000),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Text(
                          'Payment Method',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    height: 85,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: AppColors.secondary),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(PhosphorIconsRegular.money,
                                color: Color(0xFFF3F3C1), size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Pay with Cash',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF3F3C1),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // ignore: deprecated_member_use
                            Radio<String>(
                              activeColor: const Color(0xFFF3F3C1),
                              value: 'cash',
                              // ignore: deprecated_member_use
                              onChanged: (_) {},
                              // ignore: deprecated_member_use
                              groupValue: 'cash',
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cash instruction
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Have ${Fmt.currency(amount)} ready to pay your collector on arrival.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: AppButton(
                      label: S.of(context).confirmBooking,
                      onPressed: _showSuccess,
                    ),
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
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(20),
                        border: Border.all(
                            color: AppColors.primary.withAlpha(80), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          PhosphorIconsRegular.checkCircle,
                          color: AppColors.primary,
                          size: 60,
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
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.secondary,
                          ),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(
                        isNow
                            ? 'A collector is being assigned.\nExpected arrival: ~15 minutes.'
                            : 'Your scheduled pickup has been confirmed.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
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
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(S.of(context).bookingRef,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary,
                                )),
                            Text(
                              '#$ref',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: AppColors.secondary.withAlpha(40)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(S.of(context).amountPaid,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary,
                                )),
                            Text(
                              Fmt.currency(amount),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: AppColors.secondary.withAlpha(40)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary,
                                )),
                            Text(
                              Fmt.paymentMethodLabel(_paymentMethod),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: AppButton(
                          label: S.of(context).trackPickup,
                          onPressed: _trackPickup,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Download Receipt
                      GestureDetector(
                        onTap: () => ReceiptService.shareReceipt(widget.booking),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF90D8FF)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(S.of(context).downloadReceipt,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
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
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
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
      ),
    );
  }
}
