import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddressSelectionSheet extends StatelessWidget {
  const AddressSelectionSheet({
    super.key,
    required this.currentAddress,
    required this.onAddressConfirmed,
    required this.onCancel,
    this.showHandle = true,
  });

  final String currentAddress;
  final Function(String) onAddressConfirmed;
  final VoidCallback onCancel;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: currentAddress);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: showHandle ? const BorderRadius.vertical(top: Radius.circular(24)) : null,
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confirm Pickup Location', style: AppTextStyles.h2),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: ctrl,
            label: 'ADDRESS',
            hint: 'Enter specific address or landmark',
            prefixIcon: Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill), size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Confirm Address',
            onPressed: () => onAddressConfirmed(ctrl.text),
          ),
        ],
      ),
    );
  }
}
