import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';

class CollectorEditProfileScreen extends StatefulWidget {
  const CollectorEditProfileScreen({super.key});

  @override
  State<CollectorEditProfileScreen> createState() =>
      _CollectorEditProfileScreenState();
}

class _CollectorEditProfileScreenState
    extends State<CollectorEditProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _plateCtrl   = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  String? _vehicleType;
  bool _saving = false;

  static const _vehicleTypes = ['Tricycle', 'Pickup Truck', 'Mini Truck', 'Van', 'Other'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text  = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _plateCtrl.text = user?.vehiclePlate ?? '';
    _vehicleType    = user?.vehicleType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiClient.put('/api/profile', {
        'fullName':     _nameCtrl.text.trim(),
        'phone':        _phoneCtrl.text.trim(),
        'vehicleType':  _vehicleType,
        'vehiclePlate': _plateCtrl.text.trim(),
      });
      if (!mounted) return;
      final updated = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
      context.read<AuthProvider>().updateUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.secondary),
                    ),
                    Expanded(
                      child: Text('Edit Profile', style: AppTextStyles.appBarTitle.copyWith(
                        color: AppColors.secondary)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Center(
                          child: Consumer<AuthProvider>(
                            builder: (_, auth, __) {
                              final name = _nameCtrl.text.isNotEmpty
                                  ? _nameCtrl.text
                                  : (auth.user?.fullName ?? '?');
                              return Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _initials(name),
                                    style: AppTextStyles.h3.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Full name
                        Text('Full Name', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _nameCtrl,
                          label: '',
                          hint: 'Your full name',
                          prefixIcon: const Icon(PhosphorIconsRegular.user,
                              color: AppColors.muted, size: 20),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Name is required'
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 20),

                        // Phone
                        Text('Phone Number', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _phoneCtrl,
                          label: '',
                          hint: '+233 xx xxx xxxx',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(PhosphorIconsRegular.phone,
                              color: AppColors.muted, size: 20),
                        ),

                        const SizedBox(height: 20),

                        // Vehicle type
                        Text('Vehicle Type', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: AppRadius.lgBR,
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _vehicleType,
                              hint: Text('Select vehicle type',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.muted)),
                              isExpanded: true,
                              dropdownColor: AppColors.card,
                              style: AppTextStyles.body,
                              items: _vehicleTypes
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _vehicleType = v),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Vehicle plate
                        Text('Vehicle Plate Number', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _plateCtrl,
                          label: '',
                          hint: 'e.g. GR-1234-23',
                          prefixIcon: const Icon(PhosphorIconsRegular.truck,
                              color: AppColors.muted, size: 20),
                        ),

                        const SizedBox(height: 36),

                        AppButton(
                          label: 'Save Changes',
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
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}
