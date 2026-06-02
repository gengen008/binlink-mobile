import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _phoneCtrl    = TextEditingController();
  final _otpCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  // Steps: 0=phone, 1=otp, 2=new password
  int _step = 0;
  bool _showPassword = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_phoneCtrl.text.trim());
    if (!mounted) return;
    if (ok) setState(() => _step = 1);
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      phone:       _phoneCtrl.text.trim(),
      otp:         _otpCtrl.text.trim(),
      newPassword: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset! Please sign in.'), backgroundColor: AppColors.success),
      );
      Navigator.pushReplacementNamed(context, '/login');
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
                    onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text('Reset password', style: AppTextStyles.h2),
                        const SizedBox(height: 8),
                        Text(
                          _step == 0
                            ? 'Enter your phone number to receive a reset code.'
                            : _step == 1
                              ? 'Enter the code sent to your phone and choose a new password.'
                              : '',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // Step 0 — phone
                        if (_step == 0) ...[
                          AppTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            hint: '+233 XX XXX XXXX',
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(PhosphorIconsRegular.phone, color: AppColors.muted, size: 20),
                            validator: Validators.phone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _sendOtp(),
                          ),
                          const SizedBox(height: 32),
                          AppButton(label: 'Send Code', loading: auth.loading, onPressed: _sendOtp),
                        ],

                        // Step 1 — OTP + new password
                        if (_step == 1) ...[
                          AppTextField(
                            controller: _otpCtrl,
                            label: 'Verification Code',
                            hint: '6-digit code',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(PhosphorIconsRegular.shield, color: AppColors.muted, size: 20),
                            validator: Validators.otp,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passCtrl,
                            label: 'New Password',
                            hint: 'At least 8 characters',
                            obscureText: !_showPassword,
                            prefixIcon: const Icon(PhosphorIconsRegular.lock, color: AppColors.muted, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _showPassword = !_showPassword),
                              child: Icon(
                                _showPassword ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                                color: AppColors.muted, size: 20,
                              ),
                            ),
                            validator: Validators.password,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmCtrl,
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            obscureText: !_showPassword,
                            prefixIcon: const Icon(PhosphorIconsRegular.lockKey, color: AppColors.muted, size: 20),
                            validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _reset(),
                          ),
                          const SizedBox(height: 32),
                          AppButton(label: 'Reset Password', loading: auth.loading, onPressed: _reset),
                        ],
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
