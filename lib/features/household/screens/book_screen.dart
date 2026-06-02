import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'payment_screen.dart';

// Pricing
const Map<String, double> _binPrices = {
  'SMALL': 30, 'MEDIUM': 40, 'LARGE': 50,
};
const double _bagPrice = 6;

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _addressCtrl = TextEditingController();

  String _binSize = 'SMALL';
  int _extraBags = 0;
  String _paymentMethod = 'MTN_MOMO';
  double _lat = 5.6037;
  double _lng = -0.1870;
  bool _locating = false;

  double get _total =>
      (_binPrices[_binSize] ?? 30) + (_extraBags * _bagPrice);

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locating = false;
      });
    } else {
      setState(() => _locating = false);
    }
  }

  Future<void> _proceed() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup address'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final prov = context.read<HouseholdProvider>();
    final booking = await prov.createBooking(
      binSize: _binSize,
      extraBags: _extraBags,
      pickupAddress: _addressCtrl.text.trim(),
      pickupLat: _lat,
      pickupLng: _lng,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    if (booking != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(booking: booking),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error ?? 'Failed to create booking'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                    ),
                    const Expanded(child: Text('Schedule Pickup', style: AppTextStyles.h3)),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bin size
                      Text('Bin Size', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      ..._binPrices.entries.map((e) => _BinOption(
                        size: e.key,
                        price: e.value,
                        selected: _binSize == e.key,
                        onTap: () => setState(() => _binSize = e.key),
                      )),

                      const SizedBox(height: 24),

                      // Extra bags
                      Row(
                        children: [
                          Text('Extra Bags', style: AppTextStyles.label),
                          const Spacer(),
                          Text('GHC ${_bagPrice.toStringAsFixed(0)} each',
                              style: AppTextStyles.monoSm),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            _IconBtn(
                              icon: PhosphorIconsRegular.minus,
                              onTap: () { if (_extraBags > 0) setState(() => _extraBags--); },
                            ),
                            Expanded(
                              child: Text(
                                '$_extraBags',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.monoLg,
                              ),
                            ),
                            _IconBtn(
                              icon: PhosphorIconsRegular.plus,
                              onTap: () => setState(() => _extraBags++),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pickup address
                      AppTextField(
                        controller: _addressCtrl,
                        label: 'Pickup Address',
                        hint: 'Enter your address',
                        maxLines: 2,
                        prefixIcon: _locating
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.steelBlue),
                                ),
                              )
                            : const Icon(PhosphorIconsRegular.mapPin, color: AppColors.muted, size: 20),
                      ),

                      const SizedBox(height: 24),

                      // Payment method
                      Text('Payment Method', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      ...['MTN_MOMO', 'VODAFONE_CASH', 'AIRTELTIGO', 'CASH'].map((m) => _PaymentOption(
                        method: m,
                        selected: _paymentMethod == m,
                        onTap: () => setState(() => _paymentMethod = m),
                      )),

                      const SizedBox(height: 32),

                      // Total summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.steelBlue.withAlpha(60)),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow('Bin (${Fmt.binSizeLabel(_binSize)})',
                                Fmt.currency(_binPrices[_binSize]!)),
                            if (_extraBags > 0) ...[
                              const SizedBox(height: 8),
                              _SummaryRow('Extra Bags (×$_extraBags)',
                                  Fmt.currency(_extraBags * _bagPrice)),
                            ],
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total', style: AppTextStyles.h4),
                                Text(Fmt.currency(_total),
                                    style: AppTextStyles.monoLg.copyWith(color: AppColors.iceBlue)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Confirm Booking',
                        loading: prov.loading,
                        onPressed: _proceed,
                        icon: const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.white, size: 20),
                      ),
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

class _BinOption extends StatelessWidget {
  const _BinOption({
    required this.size, required this.price,
    required this.selected, required this.onTap,
  });
  final String size;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.steelBlue : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsFill.trashSimple,
                color: selected ? AppColors.white : AppColors.muted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.binSizeLabel(size),
                      style: AppTextStyles.h4.copyWith(
                        color: selected ? AppColors.white : AppColors.textPrimary,
                      )),
                ],
              ),
            ),
            Text(
              Fmt.currency(price),
              style: AppTextStyles.mono.copyWith(
                color: selected ? AppColors.white : AppColors.iceBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.method, required this.selected, required this.onTap,
  });
  final String method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.steelBlue.withAlpha(25) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.steelBlue : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method == 'CASH' ? PhosphorIconsRegular.money : PhosphorIconsRegular.deviceMobile,
              color: selected ? AppColors.steelBlue : AppColors.muted, size: 20,
            ),
            const SizedBox(width: 12),
            Text(Fmt.paymentMethodLabel(method),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected ? AppColors.steelBlue : AppColors.textPrimary,
                )),
            const Spacer(),
            if (selected)
              const Icon(PhosphorIconsFill.checkCircle, color: AppColors.steelBlue, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.monoSm.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.steelBlue.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.steelBlue, size: 18),
      ),
    );
  }
}
