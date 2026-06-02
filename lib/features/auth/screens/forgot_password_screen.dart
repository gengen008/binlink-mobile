import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error'), backgroundColor: AppColors.danger),
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
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _sent ? _SuccessView(email: _emailCtrl.text.trim()) : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text('Reset password', style: AppTextStyles.h2),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your email and we\'ll send you a link to reset your password.',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          prefixIcon: const Icon(PhosphorIconsRegular.envelope, color: AppColors.muted, size: 20),
                          validator: Validators.email,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _sendReset(),
                        ),

                        const SizedBox(height: 32),

                        AppButton(
                          label: 'Send Reset Link',
                          loading: auth.loading,
                          onPressed: _sendReset,
                        ),
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

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(20),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withAlpha(60), width: 2),
          ),
          child: const Center(
            child: Icon(PhosphorIconsRegular.envelopeOpen, color: AppColors.success, size: 32),
          ),
        ),
        const SizedBox(height: 24),
        Text('Check your email', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent to\n$email',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ],
    );
  }
}
