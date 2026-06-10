import 'package:animate_do/animate_do.dart';
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
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
      phone:    _phoneCtrl.text.trim(),
      role:     FlavorConfig.defaultRole,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else {
      _showError(auth.error ?? 'Registration failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                            child: Icon(PhosphorIcons.arrowLeft(), size: 20, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        FadeInDown(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Join BinLink",
                                style: AppTextStyles.h1.copyWith(height: 1.1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                FlavorConfig.registerSubtitle,
                                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        FadeInUp(
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _nameCtrl,
                                label: 'FULL NAME',
                                hint: 'John Doe',
                                prefixIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill), size: 20),
                                validator: Validators.required,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _emailCtrl,
                                label: 'EMAIL ADDRESS',
                                hint: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(PhosphorIcons.envelopeSimple(PhosphorIconsStyle.fill), size: 20),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _phoneCtrl,
                                label: 'PHONE NUMBER',
                                hint: '024XXXXXXX',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icon(PhosphorIcons.phone(PhosphorIconsStyle.fill), size: 20),
                                validator: Validators.phone,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _passCtrl,
                                label: 'PASSWORD',
                                hint: 'Create password',
                                obscureText: true,
                                showToggle: true,
                                prefixIcon: Icon(PhosphorIcons.lockKey(PhosphorIconsStyle.fill), size: 20),
                                validator: Validators.password,
                              ),
                              const SizedBox(height: 32),
                              AppButton(
                                label: 'Create Account',
                                loading: auth.loading,
                                onPressed: _register,
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),

                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Already have an account? ",
                                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                    children: [
                                      TextSpan(
                                        text: "Sign in",
                                        style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
