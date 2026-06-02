import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _momoCtrl = TextEditingController();
  bool _paying = false;

  String get _paymentMethod => widget.booking['paymentMethod'] as String? ?? 'CASH';
  bool get _isMoMo => _paymentMethod != 'CASH';

  @override
  void dispose() {
    _momoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_isMoMo && _momoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your MoMo number'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _paying = true);

    final prov = context.read<HouseholdProvider>();
    final ok = await prov.initiatePayment(
      widget.booking['id'] as String,
      _momoCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() { _paying = false; });

    if (ok) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(bookingId: widget.booking['id'] as String),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please check your MoMo number and try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _skipToCash() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(bookingId: widget.booking['id'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.booking['totalAmount'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      body: Container(
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
                      icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                    ),
                    const Expanded(child: Text('Payment', style: AppTextStyles.h3)),
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
                            const Icon(PhosphorIconsFill.wallet, color: AppColors.white, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              Fmt.currency(amount),
                              style: AppTextStyles.monoLg.copyWith(fontSize: 32, color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'via ${Fmt.paymentMethodLabel(_paymentMethod)}',
                              style: AppTextStyles.label.copyWith(color: AppColors.iceBlue),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      if (_isMoMo) ...[
                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.warning.withAlpha(60)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.info, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 8),
                                  Text('How to pay', style: AppTextStyles.label.copyWith(color: AppColors.warning)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. Enter your ${Fmt.paymentMethodLabel(_paymentMethod)} number below\n'
                                '2. Tap "Pay Now" — you\'ll receive a USSD prompt\n'
                                '3. Approve the payment on your phone',
                                style: AppTextStyles.caption.copyWith(color: AppColors.warning, height: 1.7),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        AppTextField(
                          controller: _momoCtrl,
                          label: '${Fmt.paymentMethodLabel(_paymentMethod)} Number',
                          hint: '024 XXX XXXX',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(PhosphorIconsRegular.deviceMobile, color: AppColors.muted, size: 20),
                        ),

                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Pay Now',
                          loading: _paying,
                          onPressed: _pay,
                          icon: const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.white, size: 20),
                        ),
                      ] else ...[
                        // Cash
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.success.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsFill.money, color: AppColors.success, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pay in Cash', style: AppTextStyles.h4.copyWith(color: AppColors.success)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Have ${Fmt.currency(amount)} ready to pay your collector on arrival.',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.success),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Track My Pickup',
                          onPressed: _skipToCash,
                          icon: const Icon(PhosphorIconsRegular.mapPin, color: AppColors.white, size: 20),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
