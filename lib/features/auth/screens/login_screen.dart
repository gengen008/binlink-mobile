import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../components/auth_header.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo + brand header
                authHeader(context),

                const SizedBox(height: 36),

                // Form section
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
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
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FlavorConfig.isCollector
                              ? 'Sign in to your collector account'
                              : 'Book waste pickups at affordable rates',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
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
                                color: AppColors.primary,
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

                const SizedBox(height: 16),

                // Divider
                FadeInUp(
                  duration: const Duration(milliseconds: 550),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _GoogleButton(
                      loading: auth.loading,
                      onPressed: _loginGoogle,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                FadeInUp(
                  duration: const Duration(milliseconds: 650),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Sign up',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
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
    );
  }
}

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
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.buttonBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.google, width: 20, height: 20),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: AppTextStyles.button.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
