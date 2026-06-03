import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _regCtrl   = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  String  _vehicleType = 'PICKUP_TRUCK';
  double  _maxCapacity = 500;
  bool    _saving      = false;

  static const _types = [
    {'key': 'PICKUP_TRUCK', 'label': 'Pickup Truck',  'icon': PhosphorIconsFill.truck},
    {'key': 'TIPPER',       'label': 'Tipper Truck',  'icon': PhosphorIconsFill.truck},
    {'key': 'TRICYCLE',     'label': 'Tricycle',      'icon': PhosphorIconsFill.motorcycle},
    {'key': 'MOTORBIKE',    'label': 'Motorbike',     'icon': PhosphorIconsFill.motorcycle},
    {'key': 'VAN',          'label': 'Van',           'icon': PhosphorIconsFill.van},
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.vehicleType != null) _vehicleType = user!.vehicleType!;
    if (user?.vehiclePlate != null) _regCtrl.text = user!.vehiclePlate!;
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    _colorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiClient.put('/api/profile', {
        'vehicleType':   _vehicleType,
        'vehiclePlate':  _regCtrl.text.trim(),
        'maxCapacityKg': _maxCapacity,
      });
      if (!mounted) return;
      final updated = UserModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
      context.read<AuthProvider>().updateUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle details saved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save vehicle details'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.white),
                    ),
                    const Expanded(
                      child: Text('Vehicle Details', style: AppTextStyles.h3),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vehicle Type', style: AppTextStyles.label),
                        const SizedBox(height: 12),

                        // Type selector
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _types.map((t) {
                            final sel = _vehicleType == t['key'];
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _vehicleType = t['key'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: sel
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: sel ? null : AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.steelBlue
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(t['icon'] as IconData,
                                        color: sel
                                            ? AppColors.white
                                            : AppColors.muted,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text(t['label'] as String,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: sel
                                              ? AppColors.white
                                              : AppColors.textPrimary,
                                          fontSize: 13,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),
                        const Text('Registration Number', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _regCtrl,
                          label: '',
                          hint: 'e.g. GR 1234-23',
                          prefixIcon: const Icon(
                            PhosphorIconsRegular.identificationCard,
                            color: AppColors.muted, size: 20,
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Registration number required'
                              : null,
                        ),

                        const SizedBox(height: 20),
                        const Text('Vehicle Color', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _colorCtrl,
                          label: '',
                          hint: 'e.g. White, Red',
                          prefixIcon: const Icon(
                            PhosphorIconsRegular.palette,
                            color: AppColors.muted, size: 20,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('Max Capacity', style: AppTextStyles.label),
                            const Spacer(),
                            Text('${_maxCapacity.toInt()}kg',
                                style: AppTextStyles.monoSm.copyWith(
                                  color: AppColors.iceBlue,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.steelBlue,
                            inactiveTrackColor: AppColors.border,
                            thumbColor: AppColors.steelBlue,
                            overlayColor: AppColors.steelBlue.withAlpha(30),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _maxCapacity,
                            min: 100,
                            max: 2000,
                            divisions: 19,
                            onChanged: (v) =>
                                setState(() => _maxCapacity = v),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text('Notes (optional)', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _notesCtrl,
                          label: '',
                          hint: 'Any additional vehicle info',
                          maxLines: 2,
                          prefixIcon: const Icon(
                            PhosphorIconsRegular.notepad,
                            color: AppColors.muted, size: 20,
                          ),
                        ),

                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Save Vehicle Details',
                          loading: _saving,
                          onPressed: _save,
                          icon: const Icon(PhosphorIconsRegular.checkCircle,
                              color: AppColors.white, size: 20),
                        ),
                      ],
                    ),
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
