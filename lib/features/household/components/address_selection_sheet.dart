import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddressSelectionSheet extends StatefulWidget {
  const AddressSelectionSheet({
    super.key,
    required this.currentAddress,
    required this.onAddressConfirmed,
    required this.onCancel,
    this.showHandle = true,
  });

  final String currentAddress;
  final Function(String address) onAddressConfirmed;
  final VoidCallback onCancel;
  final bool showHandle;

  @override
  State<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<AddressSelectionSheet> {
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.showHandle ? const BorderRadius.vertical(top: Radius.circular(32)) : null,
        boxShadow: widget.showHandle ? [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))] : null,
      ),
      padding: EdgeInsets.fromLTRB(24, widget.showHandle ? 12 : 0, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHandle) ...[
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confirm Pickup', style: AppTextStyles.h2),
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Use AppTextField to conform to the design system.
          AppTextField(
            controller: _addressCtrl,
            label: 'LOCATION',
            hint: 'Pickup address',
            prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
          ),
          
          const SizedBox(height: 16),

          // Map Thumbnail Preview placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary300.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.map, color: AppColors.primary900, size: 32),
                  const SizedBox(height: 8),
                  Text('Map Preview', style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          
          FadeInUp(
            child: AppButton(
              label: 'Confirm Location',
              onPressed: () => widget.onAddressConfirmed(_addressCtrl.text),
            ),
          ),
        ],
      ),
    );
  }
}
