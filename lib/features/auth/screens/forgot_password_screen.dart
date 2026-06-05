import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: CustomPaint(painter: _AuthBgPainter())),

          // Hero section
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.42,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.cardElevated,
                            borderRadius: AppRadius.smBR,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(PhosphorIconsRegular.arrowLeft,
                              color: AppColors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Icon
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 60),
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(25),
                          borderRadius: AppRadius.xlBR,
                          border: Border.all(
                              color: AppColors.steelBlue.withAlpha(80)),
                        ),
                        child: const Icon(PhosphorIconsRegular.envelopeSimple,
                            color: AppColors.steelBlue, size: 28),
                      ),
                    ),
                    const SizedBox(height: 20),

                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        'Forgot your\npassword?',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 34,
                          height: 1.15,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 180),
                      child: Text(
                        "No worries. We'll send a reset link to your email.",
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form / success card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 220),
              child: Container(
                constraints: BoxConstraints(maxHeight: size.height * 0.65),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                    left: BorderSide(color: AppColors.border),
                    right: BorderSide(color: AppColors.border),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                    24, 20, 24,
                    MediaQuery.viewInsetsOf(context).bottom + 32),
                child: _sent
                    ? _SuccessView(email: _emailCtrl.text.trim())
                    : _FormView(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        loading: auth.loading,
                        onSubmit: _sendReset,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.onSubmit,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.sheetHandle,
                borderRadius: AppRadius.fullBR,
              ),
            ),
          ),
          Text('Reset your password', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Enter the email linked to your account',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),

          AppTextField(
            controller: emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            prefixIcon: const Icon(PhosphorIconsRegular.envelope,
                color: AppColors.muted, size: 20),
            validator: Validators.email,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 28),

          AppButton(
            label: 'Send Reset Link',
            loading: loading,
            onPressed: onSubmit,
            icon: const Icon(PhosphorIconsRegular.paperPlaneTilt,
                color: AppColors.white, size: 18),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: AppColors.sheetHandle,
              borderRadius: AppRadius.fullBR,
            ),
          ),
        ),
        ZoomIn(
          duration: const Duration(milliseconds: 600),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.success.withAlpha(80), width: 2),
            ),
            child: const Icon(PhosphorIconsRegular.envelopeOpen,
                color: AppColors.success, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Text('Link sent!', style: AppTextStyles.h2,
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 10),
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 80),
          child: Text(
            'A password reset link has been sent to\n$email',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 160),
          child: AppButton(
            label: 'Back to Sign In',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
          ),
        ),
      ],
    );
  }
}

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.steelBlue.withAlpha(18);
    canvas.drawCircle(Offset(size.width + 40, -60), 200, paint);
    paint.color = AppColors.deepOcean.withAlpha(180);
    canvas.drawCircle(Offset(-60, size.height * 0.5), 160, paint);
    final dotPaint = Paint()
      ..color = AppColors.steelBlue.withAlpha(16)
      ..style = PaintingStyle.fill;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height * 0.44; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => false;
}
