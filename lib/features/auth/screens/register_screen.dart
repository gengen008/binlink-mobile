import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withAlpha(40),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                    child: const Icon(LucideIcons.arrowLeft, size: 20),
                  ),
                ),
                const SizedBox(height: 32),
                
                FadeInDown(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Join BinLink",
                        style: AppTextStyles.display.copyWith(fontSize: 36, height: 1.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        FlavorConfig.registerSubtitle,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                FadeInUp(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'FULL NAME',
                        hint: 'John Doe',
                        prefixIcon: const Icon(LucideIcons.user, size: 20),
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'EMAIL ADDRESS',
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(LucideIcons.mail, size: 20),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'PHONE NUMBER',
                        hint: '024XXXXXXX',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(LucideIcons.phone, size: 20),
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _passCtrl,
                        label: 'PASSWORD',
                        hint: 'Create password',
                        obscureText: true,
                        showToggle: true,
                        prefixIcon: const Icon(LucideIcons.lock, size: 20),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 40),
                      AppButton(
                        label: 'Create Account',
                        loading: auth.loading,
                        onPressed: _register,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text: "Sign in",
                              style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
              ),
              ),
              ),
              ),
              ),
              );
              }
}
