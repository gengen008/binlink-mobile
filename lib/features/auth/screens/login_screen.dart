import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      final user = auth.user!;
      if (user.isPending) {
        Navigator.pushReplacementNamed(context, '/pending');
      } else if (user.isCollector) {
        Navigator.pushReplacementNamed(context, '/collector');
      } else {
        Navigator.pushReplacementNamed(context, '/household');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: AppColors.danger),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Header
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('BL', style: TextStyle(
                        fontFamily: 'PlusJakartaSans', fontSize: 22,
                        fontWeight: FontWeight.w800, color: AppColors.white,
                      )),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Welcome back', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your BinLink account',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  // Phone
                  AppTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    hint: '+233 XX XXX XXXX',
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    prefixIcon: const Icon(PhosphorIconsRegular.phone, color: AppColors.muted, size: 20),
                    validator: Validators.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  AppTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.password],
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
                    onFieldSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.label.copyWith(color: AppColors.steelBlue),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  AppButton(
                    label: 'Sign In',
                    loading: auth.loading,
                    onPressed: _login,
                  ),

                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppTextStyles.body.copyWith(color: AppColors.muted)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text('Sign Up', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.steelBlue)),
                      ),
                    ],
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
