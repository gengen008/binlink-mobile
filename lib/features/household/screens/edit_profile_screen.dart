import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool _saving       = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text    = user?.fullName ?? '';
    _addressCtrl.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiClient.put('/api/profile', {
        'fullName': _nameCtrl.text.trim(),
        'address':  _addressCtrl.text.trim(),
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
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
                      child: Text('Edit Profile', style: AppTextStyles.h3),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar preview
                        Center(
                          child: Consumer<AuthProvider>(
                            builder: (_, auth, __) {
                              final initials = _nameCtrl.text.isNotEmpty
                                  ? _initials(_nameCtrl.text)
                                  : _initials(auth.user?.fullName ?? '?');
                              return Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.steelBlue.withAlpha(80),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: AppTextStyles.h2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),
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
                        Text('Primary Address', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _addressCtrl,
                          label: '',
                          hint: 'Your home address',
                          maxLines: 2,
                          prefixIcon: const Icon(PhosphorIconsRegular.mapPin,
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
