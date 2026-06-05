// Trippo forgot_password — architecture transplant.
//
// Trippo source structure:
//   Scaffold(dark) > Stack([Opacity(0.15, main.jpg), SafeArea > ScrollView])
//
// BinLink replacements:
//   - sendPasswordReset() API call
//   - _sent success state (BinLink addition)

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../components/auth_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/rydr_assets.dart';
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
        SnackBar(
          content: Text(auth.error ?? 'Error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.secondary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.15,
            child: Image.asset(RydrAssets.authBg, fit: BoxFit.cover),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  authHeader(context),

                  const SizedBox(height: 40),

                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Password',
                            style: AppTextStyles.h2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your email address to receive a reset link.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xB3FFFFFF),
                            ),
                          ),
                          const SizedBox(height: 28),

                          if (!_sent) ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _sendReset(),
                                    fillColor: AppColors.fieldFill,
                                    textColor: AppColors.secondary,
                                    labelColor: const Color(0xB3FFFFFF),
                                  ),
                                  const SizedBox(height: 24),
                                  AppButton(
                                    label: 'Send Reset Link',
                                    loading: auth.loading,
                                    onPressed: _sendReset,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Success state
                            const SizedBox(height: 10),
                            Center(
                              child: ZoomIn(
                                duration: const Duration(milliseconds: 600),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      PhosphorIconsRegular.envelopeOpen,
                                      color: AppColors.accent,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: FadeInUp(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  'Link Sent!',
                                  style: AppTextStyles.h3.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: FadeInUp(
                                duration: const Duration(milliseconds: 500),
                                delay: const Duration(milliseconds: 80),
                                child: Text(
                                  'A password reset link has been sent to\n${_emailCtrl.text.trim()}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xB3FFFFFF),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            FadeInUp(
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 160),
                              child: AppButton(
                                label: 'Back to Sign In',
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/login'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
