import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: const AppScaffoldBar(title: 'Edit Profile'),
      body: Column(
          children: [
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCE1DE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2421),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Your full name',
                          prefixIcon: const Icon(PhosphorIconsRegular.user,
                              color: AppColors.muted, size: 20),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Name is required'
                              : null,
                          onChanged: (_) => setState(() {}),
                          fillColor: const Color(0xFFF5F6F5),
                          textColor: const Color(0xFF1F2421),
                          labelColor: const Color(0xFF1F2421),
                        ),

                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _addressCtrl,
                          label: 'Primary Address',
                          hint: 'Your home address',
                          maxLines: 2,
                          prefixIcon: const Icon(PhosphorIconsRegular.mapPin,
                              color: AppColors.muted, size: 20),
                          fillColor: const Color(0xFFF5F6F5),
                          textColor: const Color(0xFF1F2421),
                          labelColor: const Color(0xFF1F2421),
                        ),

                        const SizedBox(height: 30),
                        AppButton(
                          label: 'Save Changes',
                          loading: _saving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
