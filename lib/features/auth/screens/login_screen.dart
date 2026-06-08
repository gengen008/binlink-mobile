import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // ── Uber Style Header ──
                FadeInDown(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80, height: 80,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
                        child: Image.asset(AppAssets.bin3d),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        FlavorConfig.isCollector ? "Hello Collector," : "Hello,",
                        style: AppTextStyles.h1,
                      ),
                      Text(
                        "Sign in to continue",
                        style: AppTextStyles.h2.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                FadeInUp(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(PhosphorIconsRegular.envelope, size: 20),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _passCtrl,
                        label: 'Password',
                        hint: 'Enter password',
                        obscureText: true,
                        showToggle: true,
                        prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 20),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Sign In',
                        loading: auth.loading,
                        onPressed: _loginEmail,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR", style: AppTextStyles.label),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _GoogleButtonV4(
                    onPressed: _loginGoogle,
                    loading: auth.loading,
                  ),
                ),

                const SizedBox(height: 40),

                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.bodySmall,
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
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

class _GoogleButtonV4 extends StatelessWidget {
  const _GoogleButtonV4({required this.onPressed, required this.loading});
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.googleIcon, width: 24, height: 24),
            const SizedBox(width: 12),
            Text("Continue with Google", style: AppTextStyles.h4),
          ],
        ),
      ),
    );
  }
}
