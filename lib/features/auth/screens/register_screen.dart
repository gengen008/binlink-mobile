import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _showPass   = false;

  final String _role = FlavorConfig.defaultRole;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerWithEmail(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role:     _role,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error ?? 'Registration failed'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _registerGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle(role: _role);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error!), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _AuthBgPainter()),
          ),

          // ── Hero section ──────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.38,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
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
                    const SizedBox(height: 24),

                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Create\naccount.',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 36,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 160),
                      child: Text(
                        FlavorConfig.registerSubtitle,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form card ─────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: Container(
                constraints: BoxConstraints(maxHeight: size.height * 0.72),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      24, 20, 24,
                      MediaQuery.viewInsetsOf(context).bottom + 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
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

                        Text('Your details', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('Fill in your information to get started',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 22),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.steelBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.steelBlue.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FlavorConfig.isCollector
                                    ? PhosphorIconsFill.truck
                                    : PhosphorIconsFill.house,
                                color: AppColors.steelBlue,
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                FlavorConfig.isCollector
                                    ? 'Collector account'
                                    : 'Household account',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.steelBlue,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Full name
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Your full name',
                          autofillHints: const [AutofillHints.name],
                          prefixIcon: const Icon(PhosphorIconsRegular.user,
                              color: AppColors.muted, size: 20),
                          validator: (v) => Validators.required(v, 'Full name'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Email address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          prefixIcon: const Icon(PhosphorIconsRegular.envelope,
                              color: AppColors.muted, size: 20),
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'At least 8 characters',
                          obscureText: !_showPass,
                          autofillHints: const [AutofillHints.newPassword],
                          prefixIcon: const Icon(PhosphorIconsRegular.lock,
                              color: AppColors.muted, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _showPass = !_showPass),
                            child: Icon(
                              _showPass
                                  ? PhosphorIconsRegular.eyeSlash
                                  : PhosphorIconsRegular.eye,
                              color: AppColors.muted, size: 20,
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                        ),
                        const SizedBox(height: 22),

                        // Create account button
                        AppButton(
                          label: 'Create Account',
                          loading: auth.loading,
                          onPressed: _register,
                        ),
                        const SizedBox(height: 18),

                        // Divider
                        Row(children: [
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('or',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.muted)),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                        ]),
                        const SizedBox(height: 16),

                        // Google
                        _GoogleRegisterButton(
                            loading: auth.loading,
                            onPressed: _registerGoogle),
                        const SizedBox(height: 22),

                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.muted)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text('Sign In',
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.steelBlue)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────

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
      for (double y = 0; y < size.height * 0.42; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => false;
}

// ── Google register button ────────────────────────────────────────────────────

class _GoogleRegisterButton extends StatelessWidget {
  const _GoogleRegisterButton(
      {required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: AppRadius.smBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22, height: 22,
              child: CustomPaint(painter: _GLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text('Sign up with Google',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

class _GLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final colours = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18;
    const s = -0.2;
    final sw = [1.65, 1.57, 1.57, 1.57];
    double st = s;
    for (int i = 0; i < 4; i++) {
      p.color = colours[i];
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
          st, sw[i], false, p);
      st += sw[i];
    }
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - size.height * 0.18, r, size.height * 0.36),
        Paint()
          ..color = AppColors.cardElevated
          ..style = PaintingStyle.fill);
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - size.height * 0.18, r * 0.85, size.height * 0.36),
        Paint()
          ..color = colours[0]
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_) => false;
}
