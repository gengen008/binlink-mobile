// Rydr forget_password.dart — literal transplant.
//
// Rydr source structure:
//   Scaffold(backgroundColor: Primarywhite) > SingleChildScrollView >
//   Column([
//     YMargin(100), authHeader(context),
//     FadeInDown(1400ms, Padding(h:30, Column([title, subtitle, field, submit])))
//   ])
//
// BinLink replacements only:
//   - Primarywhite → Colors.white
//   - sendPasswordReset() API call
//   - _sent success state added (Rydr has no success state shown — BinLink addition)

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../components/auth_header.dart';
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
        SnackBar(
            content: Text(auth.error ?? 'Error'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Rydr: Scaffold(backgroundColor: ColorPath.Primarywhite)
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rydr: YMargin(100)
              const SizedBox(height: 100),

              // Rydr: authHeader(context)
              authHeader(context),

              // Rydr: FadeInDown(1400ms, Padding(h:30, Column([title, subtitle, field, Container(submit)])))
              const SizedBox(height: 30),
              FadeInDown(
                duration: const Duration(milliseconds: 1400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot your\npassword?',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.midnightNavy,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        "No worries. We'll send a reset link to your email.",
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (!_sent) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rydr: CustomTextFieldWidget(hintText: 'Email Address')
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
                                fillColor: const Color(0xFFF5F6F5),
                                textColor: AppColors.midnightNavy,
                                labelColor: AppColors.midnightNavy,
                              ),
                              const SizedBox(height: 20),
                              // Rydr: Container(h:50, sw, br:8, Primarydark, "Submit")
                              AppButton(
                                label: 'Send Reset Link',
                                loading: auth.loading,
                                onPressed: _sendReset,
                                icon: const Icon(
                                    PhosphorIconsRegular.paperPlaneTilt,
                                    color: AppColors.white,
                                    size: 18),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Success state (BinLink addition — Rydr has no post-send state)
                        const SizedBox(height: 10),
                        Center(
                          child: ZoomIn(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(20),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.success.withAlpha(80),
                                    width: 2),
                              ),
                              child: const Icon(
                                  PhosphorIconsRegular.envelopeOpen,
                                  color: AppColors.success,
                                  size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: Text('Link sent!',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.midnightNavy,
                                ),
                                textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 80),
                            child: Text(
                              'A password reset link has been sent to\n${_emailCtrl.text.trim()}',
                              style: AppTextStyles.body.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 13),
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
    );
  }
}
