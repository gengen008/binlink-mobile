import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_text_field.dart';
import '../../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithEmail(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role:     FlavorConfig.defaultRole,
    );
    if (!mounted) return;
    if (ok) {
      _navigate(auth);
    } else {
      _showError(auth.error ?? 'Sign in failed');
    }
  }

  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle(role: FlavorConfig.defaultRole);
    if (!mounted) return;
    if (ok) {
      _navigate(auth);
    } else if (auth.error != null) {
      _showError(auth.error!);
    }
  }

  void _navigate(AuthProvider auth) {
    final user = auth.user!;
    if (FlavorConfig.isCollector && !user.isCollector) {
      _showError('Please use the Household app.');
      auth.signOut();
      return;
    }
    if (!FlavorConfig.isCollector && user.isCollector) {
      _showError('Please use the Collector app.');
      auth.signOut();
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      FlavorConfig.isCollector ? '/collector' : '/household',
    );
  }

  void _showError(String msg) {
    final colors = context.binlinkColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: colors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.binlinkColors;
    final typography = context.binlinkTypography;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.horizontalLG,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                
                // ── Brand Identity ──
                FadeInDown(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.regular), size: 48, color: colors.primary),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        FlavorConfig.isCollector ? "Welcome back,\nCollector" : "Welcome to\nBinLink",
                        style: typography.h1,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Credentials ──
                FadeInUp(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(PhosphorIcons.userCircle(PhosphorIconsStyle.regular), size: 20),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _passCtrl,
                        label: 'Password',
                        hint: '••••••••',
                        obscureText: true,
                        prefixIcon: Icon(PhosphorIcons.lockKey(PhosphorIconsStyle.regular), size: 20),
                        validator: Validators.password,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── CTA ──
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: AppButton(
                    label: 'Continue',
                    isLoading: auth.loading,
                    onPressed: _loginEmail,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: AppButton(
                    label: 'Continue with Google',
                    variant: AppButtonVariant.secondary,
                    onPressed: _loginGoogle,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Register Toggle ──
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: typography.bodyMedium,
                          children: [
                            TextSpan(
                              text: "Join now",
                              style: typography.bodyMedium.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
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
  }
}
