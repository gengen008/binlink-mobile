import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class AddressSelectionSheet extends StatefulWidget {
  const AddressSelectionSheet({
    super.key,
    required this.currentAddress,
    required this.onAddressConfirmed,
    required this.onCancel,
  });

  final String currentAddress;
  final Function(String address) onAddressConfirmed;
  final VoidCallback onCancel;

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confirm Pickup', style: AppTextStyles.h2),
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Text("LOCATION", style: AppTextStyles.label.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Pickup address',
                    ),
                    style: AppTextStyles.h4,
                  ),
                ),
              ],
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
