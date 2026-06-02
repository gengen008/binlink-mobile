import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late String _role = FlavorConfig.defaultRole;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone:    _phoneCtrl.text.trim(),
            purpose:  'REGISTRATION',
            fullName: _nameCtrl.text.trim(),
            password: _passwordCtrl.text,
            role:     _role,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to send OTP'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text('Create account', style: AppTextStyles.h1),
                        const SizedBox(height: 8),
                        Text(
                          FlavorConfig.registerSubtitle,
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // Full name
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Your full name',
                          prefixIcon: const Icon(PhosphorIconsRegular.user, color: AppColors.muted, size: 20),
                          validator: (v) => Validators.required(v, 'Full name'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        AppTextField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          hint: '+233 XX XXX XXXX',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(PhosphorIconsRegular.phone, color: AppColors.muted, size: 20),
                          validator: Validators.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        AppTextField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          hint: 'At least 8 characters',
                          obscureText: !_showPassword,
                          prefixIcon: const Icon(PhosphorIconsRegular.lock, color: AppColors.muted, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPassword = !_showPassword),
                            child: Icon(
                              _showPassword ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                              color: AppColors.muted, size: 20,
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _sendOtp(),
                        ),

                        if (_role == 'COLLECTOR') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.warning.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.info, color: AppColors.warning, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Collector accounts require admin verification before you can go online.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        AppButton(
                          label: 'Continue',
                          loading: auth.loading,
                          onPressed: _sendOtp,
                          icon: const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.white, size: 20),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text('Sign In', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.steelBlue)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
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

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChange});
  final String value;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleOption(
          label: 'Household',
          icon: PhosphorIconsRegular.house,
          selected: value == 'HOUSEHOLD',
          onTap: () => onChange('HOUSEHOLD'),
        ),
        const SizedBox(width: 12),
        _RoleOption(
          label: 'Collector',
          icon: PhosphorIconsRegular.truck,
          selected: value == 'COLLECTOR',
          onTap: () => onChange('COLLECTOR'),
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                color: selected ? AppColors.white : AppColors.muted, size: 22),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.bodyMedium.copyWith(
                color: selected ? AppColors.white : AppColors.muted,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
