import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.purpose,
    this.fullName,
    this.password,
    this.role,
    this.onVerified,
  });

  final String phone;
  final String purpose; // REGISTRATION | PASSWORD_RESET
  final String? fullName;
  final String? password;
  final String? role;
  final VoidCallback? onVerified;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() { _countdown = 60; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    if (widget.purpose == 'REGISTRATION') {
      final ok = await auth.register(
        phone:    widget.phone,
        otp:      otp,
        password: widget.password!,
        fullName: widget.fullName!,
        role:     widget.role!,
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
          SnackBar(content: Text(auth.error ?? 'Invalid OTP'), backgroundColor: AppColors.danger),
        );
      }
    } else {
      // PASSWORD_RESET — just pass OTP back
      widget.onVerified?.call();
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(widget.phone, purpose: widget.purpose);
    if (!mounted) return;
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New code sent'), backgroundColor: AppColors.success),
    );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(PhosphorIconsFill.deviceMobile,
                            color: AppColors.steelBlue, size: 28),
                      ),
                      const SizedBox(height: 24),
                      Text('Enter verification code', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'We sent a 6-digit code to '),
                            TextSpan(
                              text: widget.phone,
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // OTP input
                      OtpField(
                        controller: _otpCtrl,
                        onCompleted: _verify,
                      ),

                      const SizedBox(height: 32),

                      AppButton(
                        label: 'Verify',
                        loading: auth.loading,
                        onPressed: _verify,
                      ),

                      const SizedBox(height: 24),

                      // Resend
                      Center(
                        child: _canResend
                            ? GestureDetector(
                                onTap: _resend,
                                child: Text(
                                  'Resend code',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.steelBlue),
                                ),
                              )
                            : Text(
                                'Resend in ${_countdown}s',
                                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                              ),
                      ),
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
