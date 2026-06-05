// Trippo login_screen.dart — architecture transplant.
//
// Trippo source structure:
//   Scaffold(dark) > Stack([Opacity(0.15, main.jpg), SafeArea > ScrollView > Form])
//
// BinLink replacements:
//   - loginWithEmail() / loginWithGoogle()
//   - FlavorConfig role checks
//   - eco green primary (#16A34A) vs Trippo blue

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../components/auth_header.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/rydr_assets.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

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
      _showError('This app is for collectors. Please use the BinLink Household app.');
      auth.signOut();
      return;
    }
    if (!FlavorConfig.isCollector && user.isCollector) {
      _showError('This app is for households. Please use the BinLink Collector app.');
      auth.signOut();
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      FlavorConfig.isCollector ? '/collector' : '/household',
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Trippo: Scaffold(dark) > Stack([bg opacity 0.15, SafeArea form])
    return Scaffold(
      backgroundColor: AppColors.secondary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Trippo: Opacity(0.15, main.jpg, cover)
          Opacity(
            opacity: 0.15,
            child: Image.asset(RydrAssets.authBg, fit: BoxFit.cover),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // Logo + app name header
                    authHeader(context),

                    const SizedBox(height: 40),

                    // Form section
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FlavorConfig.isCollector
                                  ? 'Welcome Back, Collector'
                                  : 'Welcome Back',
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              FlavorConfig.isCollector
                                  ? 'Sign in to your collector account'
                                  : 'Book waste pickups at affordable rates',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xB3FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 28),

                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Email address',
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              prefixIcon: const Icon(
                                  PhosphorIconsRegular.envelope,
                                  color: AppColors.muted,
                                  size: 20),
                              validator: Validators.email,
                              textInputAction: TextInputAction.next,
                              fillColor: AppColors.fieldFill,
                              textColor: AppColors.secondary,
                              labelColor: const Color(0xB3FFFFFF),
                            ),
                            const SizedBox(height: 12),

                            AppTextField(
                              controller: _passCtrl,
                              label: 'Password',
                              hint: 'Enter your password',
                              obscureText: true,
                              showToggle: true,
                              autofillHints: const [AutofillHints.password],
                              prefixIcon: const Icon(PhosphorIconsRegular.lock,
                                  color: AppColors.muted, size: 20),
                              validator: Validators.password,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _loginEmail(),
                              fillColor: AppColors.fieldFill,
                              textColor: AppColors.secondary,
                              labelColor: const Color(0xB3FFFFFF),
                            ),
                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/forgot-password'),
                                child: Text(
                                  'Forgot password?',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            AppButton(
                              label: 'Sign In',
                              loading: auth.loading,
                              onPressed: _loginEmail,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _GoogleButton(
                          loading: auth.loading,
                          onPressed: _loginGoogle,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xB3FFFFFF),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: Text(
                              'Sign up',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google sign-in button — Trippo dark overlay style ────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: AppRadius.buttonBR,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: AppRadius.buttonBR,
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(RydrAssets.google, width: 20, height: 20),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
