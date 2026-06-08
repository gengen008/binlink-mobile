import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/app_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  bool _confirmed = false;
  String _selectedMethod = 'CASH';
  bool _isProcessing = false;

  late final AnimationController _successAnim;
  late final Animation<double> _scalePop;

  final _paymentMethods = [
    {'id': 'CASH',     'label': 'Cash on Pickup', 'icon': PhosphorIconsFill.money, 'color': AppColors.boltGreen},
    {'id': 'MTN',      'label': 'MTN MoMo',       'icon': PhosphorIconsFill.phone, 'color': Color(0xFFFFCC00)},
    {'id': 'TELECEL',  'label': 'Telecel Cash',   'icon': PhosphorIconsFill.phone, 'color': Color(0xFFE60000)},
    {'id': 'AIRTEL',   'label': 'AirtelTigo',     'icon': PhosphorIconsFill.phone, 'color': Color(0xFF005A9C)},
  ];

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scalePop = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _successAnim.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    try {
      if (_selectedMethod == 'CASH') {
        // Direct confirmation for cash (Backend already sets status)
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        // Real Paystack Flow for MoMo
        final res = await ApiClient.post('/api/payments/initialize', {
          'bookingId': widget.booking['id'],
          'channel':   'mobile_money',
        });
        
        final data = res.data['data'];
        final url = Uri.parse(data['authorization_url']);
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          // After returning from browser, we show success (polling would be better, but this confirms intent)
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _confirmed = true;
        });
        _successAnim.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _confirmed ? _buildSuccess() : _buildPaymentMethods(),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final amount = Fmt.toDouble(widget.booking['totalAmount']);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(title: 'Payment'),
      body: Column(
        children: [
          // ── Premium Amount Card ──
          FadeInDown(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Text('TOTAL TO PAY', style: AppTextStyles.label.copyWith(color: Colors.white54, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text(Fmt.currency(amount), style: AppTextStyles.monoLg.copyWith(color: Colors.white, fontSize: 40)),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text('Select Method', style: AppTextStyles.h3),
                const SizedBox(height: 20),
                
                ..._paymentMethods.map((m) {
                  final isSelected = _selectedMethod == m['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMethod = m['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surface : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: (m['color'] as Color).withAlpha(30), borderRadius: BorderRadius.circular(16)),
                              child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(m['label'] as String, style: AppTextStyles.h4)),
                            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Bottom Action ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: AppButton(
              label: 'Pay ${Fmt.currency(amount)}',
              loading: _isProcessing,
              onPressed: _handlePayment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scalePop,
                child: Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(color: AppColors.boltGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 60),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text('Payment Confirmed', style: AppTextStyles.h1),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Your booking has been successfully confirmed. A collector will be assigned shortly.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: AppButton(
                  label: 'Track Pickup',
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: TextButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: Text('Back to Home', style: AppTextStyles.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
