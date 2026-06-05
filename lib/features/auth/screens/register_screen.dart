import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
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
                // ── Top: back button (Rydr uses no back btn but BinLink needs it) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.arrowLeft,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Auth header — logo only (shorter than login) ─────────────────
                FadeInDown(
                  duration: const Duration(milliseconds: 1500),
                  child: Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'BL',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'BinLink',
                              style: AppTextStyles.h2.copyWith(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Role badge (BinLink-specific)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
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
                      ],
                    ),
                  ),
                ),

                // ── Form section (Rydr: FadeInDown 1400ms) ──────────────────────
                const SizedBox(height: 30),
                FadeInDown(
                  duration: const Duration(milliseconds: 1400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Create Account',
                          style: AppTextStyles.h2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          FlavorConfig.registerSubtitle,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Full name
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Your full name',
                          autofillHints: const [AutofillHints.name],
                          prefixIcon: const Icon(PhosphorIconsRegular.user,
                              color: AppColors.muted, size: 20),
                          validator: (v) =>
                              Validators.required(v, 'Full name'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),

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
                        const SizedBox(height: 10),

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
                            child: Text(
                              _showPass ? 'hide' : 'show',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.steelBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                        ),
                        const SizedBox(height: 20),

                        // Create account button
                        AppButton(
                          label: 'Create Account',
                          loading: auth.loading,
                          onPressed: _register,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Google register button (Rydr: FadeInDown 2000ms) ─────────────
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 2000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: _GoogleRegisterButton(
                      loading: auth.loading,
                      onPressed: _registerGoogle,
                    ),
                  ),
                ),

                // ── Sign in link (Rydr: FadeInDown 2200ms) ──────────────────────
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 2200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _GLogoPainter()),
            ),
            const SizedBox(width: 10),
            Text(
              'Sign up with Google',
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
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
    const colours = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
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
          ..color = AppColors.card
          ..style = PaintingStyle.fill);
    canvas.drawRect(
        Rect.fromLTWH(
            cx, cy - size.height * 0.18, r * 0.85, size.height * 0.36),
        Paint()
          ..color = colours[0]
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_) => false;
}
