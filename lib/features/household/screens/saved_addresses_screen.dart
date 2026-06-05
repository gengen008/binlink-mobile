import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().loadSavedAddresses();
    });
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddAddressSheet(
        onSave: (label, address, notes) async {
          final ok = await context.read<HouseholdProvider>().addSavedAddress(
            label: label,
            address: address,
            gateNotes: notes,
          );
          if (!mounted) return;
          if (ok) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Address saved!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.midnightNavy),
                    ),
                    const Expanded(
                      child: Text('Saved Addresses', style: AppTextStyles.h3),
                    ),
                    GestureDetector(
                      onTap: _showAddSheet,
                      child: Container(
                        width: 38, height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.midnightNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsRegular.plus,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Consumer<HouseholdProvider>(
                  builder: (_, prov, __) {
                    final addresses = prov.savedAddresses;

                    if (addresses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(PhosphorIconsRegular.mapPin,
                                    color: AppColors.muted, size: 32),
                              ),
                              const SizedBox(height: 20),
                              const Text('No saved addresses',
                                  style: AppTextStyles.h4),
                              const SizedBox(height: 6),
                              const Text(
                                'Add up to 5 addresses for quick booking',
                                style: AppTextStyles.caption,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                label: 'Add Address',
                                onPressed: _showAddSheet,
                                fullWidth: false,
                                height: 46,
                                icon: const Icon(PhosphorIconsRegular.plus,
                                    color: AppColors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _AddressTile(
                        address: addresses[i],
                        onDelete: () => prov.deleteSavedAddress(
                            addresses[i]['id'] as String),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ── Address tile ───────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.onDelete});
  final Map<String, dynamic> address;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label    = address['label'] as String? ?? 'Address';
    final addr     = address['address'] as String? ?? '';
    final notes    = address['gateNotes'] as String?;
    final labelColor = _labelColor(label);

    return Dismissible(
      key: Key(address['id'] as String? ?? addr),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withAlpha(80)),
        ),
        child: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger, size: 22),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: labelColor.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: labelColor.withAlpha(80)),
              ),
              child: Icon(_labelIcon(label), color: labelColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMedium.copyWith(
                    color: labelColor, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(addr, style: AppTextStyles.body.copyWith(fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notes, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsRegular.dotsThreeVertical,
                color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Color _labelColor(String label) {
    switch (label.toUpperCase()) {
      case 'HOME':   return AppColors.steelBlue;
      case 'OFFICE': return AppColors.warning;
      default:       return AppColors.skyBlue;
    }
  }

  IconData _labelIcon(String label) {
    switch (label.toUpperCase()) {
      case 'HOME':   return PhosphorIconsFill.house;
      case 'OFFICE': return PhosphorIconsFill.buildings;
      default:       return PhosphorIconsFill.mapPin;
    }
  }
}

// ── Add address sheet ──────────────────────────────────────────────────────

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet({required this.onSave});
  final Future<void> Function(String label, String address, String? notes) onSave;

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _addrCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _label    = 'HOME';
  bool _saving     = false;

  static const _labels = ['HOME', 'OFFICE', 'OTHER'];

  @override
  void dispose() {
    _addrCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Add Address', style: AppTextStyles.h3),
          const SizedBox(height: 20),

          // Label selector
          const Text('Label', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: _labels.map((l) {
              final sel = _label == l;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: l == 'OTHER' ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _label = l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : AppColors.fieldFill,
                        ),
                      ),
                      child: Center(
                        child: Text(l,
                            style: AppTextStyles.caption.copyWith(
                              color: sel ? Colors.white : AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          const Text('Address', style: AppTextStyles.label),
          const SizedBox(height: 8),
          AppTextField(
            controller: _addrCtrl,
            label: '',
            hint: 'e.g. 45 Accra-Tema Motorway, Accra',
            maxLines: 2,
            prefixIcon: const Icon(PhosphorIconsRegular.mapPin,
                color: AppColors.muted, size: 20),
          ),

          const SizedBox(height: 16),

          const Text('Gate Notes (optional)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          AppTextField(
            controller: _notesCtrl,
            label: '',
            hint: 'e.g. Blue gate, near the mango tree',
            prefixIcon: const Icon(PhosphorIconsRegular.notepad,
                color: AppColors.muted, size: 20),
          ),

          const SizedBox(height: 24),

          AppButton(
            label: 'Save Address',
            loading: _saving,
            onPressed: _addrCtrl.text.trim().isNotEmpty && !_saving
                ? () async {
                    setState(() => _saving = true);
                    await widget.onSave(
                      _label,
                      _addrCtrl.text.trim(),
                      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    );
                    if (mounted) setState(() => _saving = false);
                  }
                : null,
            icon: const Icon(PhosphorIconsRegular.checkCircle,
                color: AppColors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
