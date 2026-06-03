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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _showPass   = false;

  final String _role = FlavorConfig.defaultRole;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerWithEmail(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role:     _role,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _registerGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle(role: _role);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.danger),
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
                        const SizedBox(height: 8),
                        const Text('Create account', style: AppTextStyles.h1),
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
                          autofillHints: const [AutofillHints.name],
                          prefixIcon: const Icon(PhosphorIconsRegular.user, color: AppColors.muted, size: 20),
                          validator: (v) => Validators.required(v, 'Full name'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          prefixIcon: const Icon(PhosphorIconsRegular.envelope, color: AppColors.muted, size: 20),
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'At least 8 characters',
                          obscureText: !_showPass,
                          autofillHints: const [AutofillHints.newPassword],
                          prefixIcon: const Icon(PhosphorIconsRegular.lock, color: AppColors.muted, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPass = !_showPass),
                            child: Icon(
                              _showPass ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                              color: AppColors.muted, size: 20,
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                        ),

                        // Collector welcome
                        if (_role == 'COLLECTOR') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.success.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsFill.checkCircle, color: AppColors.success, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You can start accepting pickups immediately after signing up.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        AppButton(
                          label: 'Create Account',
                          loading: auth.loading,
                          onPressed: _register,
                          icon: const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.white, size: 20),
                        ),

                        const SizedBox(height: 20),

                        // OR divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('or', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                            ),
                            const Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Google Sign-Up
                        GestureDetector(
                          onTap: auth.loading ? null : _registerGoogle,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(PhosphorIconsRegular.googleLogo, color: AppColors.white, size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  'Sign up with Google',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
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
