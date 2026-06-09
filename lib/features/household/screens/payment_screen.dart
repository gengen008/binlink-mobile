import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _confirmed = false;
  String _selectedMethod = 'CASH';
  bool _isProcessing = false;
  final _phoneCtrl = TextEditingController();

  final _paymentMethods = [
    {'id': 'CASH',     'label': 'Pay with Cash', 'icon': LucideIcons.banknote, 'color': AppColors.success},
    {'id': 'MTN',      'label': 'MTN MoMo',       'icon': LucideIcons.smartphone, 'color': Color(0xFFFFCC00)},
    {'id': 'TELECEL',  'label': 'Telecel Cash',   'icon': LucideIcons.smartphone, 'color': Color(0xFFE60000)},
    {'id': 'AIRTEL',   'label': 'AirtelTigo',     'icon': LucideIcons.smartphone, 'color': Color(0xFF005A9C)},
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_selectedMethod != 'CASH' && _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile money number'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      if (_selectedMethod == 'CASH') {
        await Future.delayed(const Duration(milliseconds: 1200));
      } else {
        final res = await ApiClient.post('/api/payments/initialize', {
          'bookingId': widget.booking['id'],
          'channel':   'mobile_money',
        });
        final data = res.data['data'];
        final authUrl = data?['authorization_url'] as String?;
        if (authUrl == null) {
          throw Exception('Payment initialization failed: Missing authorization URL');
        }
        final url = Uri.parse(authUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch payment portal. Please check your browser settings.');
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _confirmed = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'), 
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _confirmed ? _buildSuccess() : _buildPaymentMethods(),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final amount = Fmt.toDouble(widget.booking['totalAmount']);

    return Column(
      children: [
        const AppScaffoldBar(title: 'Payment'),
        // ── Apple/Uber Style Amount Card ──
        FadeInDown(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 30, offset: const Offset(0, 15))
              ],
            ),
            child: Column(
              children: [
                Text('TOTAL TO PAY', style: AppTextStyles.small.copyWith(color: Colors.white70, letterSpacing: 2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Text(Fmt.currency(amount), style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 42)),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            children: [
              Text('PAYMENT METHOD', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              
              ..._paymentMethods.map((m) {
                final isSelected = _selectedMethod == m['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedMethod = m['id'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent, 
                              width: 2
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (m['color'] as Color).withAlpha(isSelected ? 30 : 15), 
                                  borderRadius: BorderRadius.circular(14)
                                ),
                                child: Icon(
                                  m['id'] == 'CASH' ? LucideIcons.banknote : 
                                  m['id'] == 'MTN' ? LucideIcons.smartphone :
                                  m['id'] == 'TELECEL' ? LucideIcons.phoneCall :
                                  LucideIcons.wallet,
                                  color: m['color'] as Color, size: 22
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(m['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))),
                              if (isSelected) 
                                Icon(LucideIcons.circleCheck, color: AppColors.primary, size: 24),
                            ],
                          ),
                        ),
                      ),
                      if (isSelected && m['id'] != 'CASH')
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: AppTextField(
                            controller: _phoneCtrl,
                            label: 'Mobile Money Number',
                            hint: 'e.g. 024XXXXXXX',
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(LucideIcons.phone, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // ── Bottom Action ──
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 48),
          child: AppButton(
            label: 'Pay ${Fmt.currency(amount)}',
            loading: _isProcessing,
            onPressed: _handlePayment,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final txRef = 'BL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AppAssets.lottieSuccess,
              width: 200,
              repeat: false,
              errorBuilder: (context, error, stackTrace) => const Icon(
                LucideIcons.circleCheck,
                color: AppColors.success,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  Text('Payment Confirmed', style: AppTextStyles.display.copyWith(fontSize: 32)),
                  const SizedBox(height: 16),
                  Text(
                    'Your booking has been successfully confirmed. A collector will be assigned shortly.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text("TRANSACTION REF", style: AppTextStyles.small.copyWith(fontSize: 10, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(txRef, style: AppTextStyles.mono.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: AppButton(
                label: 'Track Pickup',
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: TextButton(
                onPressed: () {
                  // TODO: Implement PDF receipt download
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading receipt...')));
                },
                child: Text('Download Receipt', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
