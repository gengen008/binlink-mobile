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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _showPass   = false;

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
      _showError('This app is for collectors. Please use the BinLink Household app.');
      auth.signOut();
      return;
    }
    if (!FlavorConfig.isCollector && user.isCollector) {
      _showError('This app is for households. Please use the BinLink Collector app.');
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background pattern ────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _AuthBgPainter()),
          ),

          // ── Hero brand section (top) ──────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.42,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo mark
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.steelBlue.withAlpha(130),
                              blurRadius: 28,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('BL', style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          )),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Welcome\nback.',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 38,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 180),
                      child: Text(
                        FlavorConfig.isCollector
                            ? 'Sign in to your collector account'
                            : 'Sign in to book waste pickups',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form card (bottom sheet) ──────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.70,
                ),
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
                      24, 28, 24,
                      MediaQuery.viewInsetsOf(context).bottom + 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sheet handle
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: AppColors.sheetHandle,
                              borderRadius: AppRadius.fullBR,
                            ),
                          ),
                        ),

                        Text('Sign In', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('Enter your credentials to continue',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 24),

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
                          hint: 'Enter your password',
                          obscureText: !_showPass,
                          autofillHints: const [AutofillHints.password],
                          prefixIcon: const Icon(PhosphorIconsRegular.lock,
                              color: AppColors.muted, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPass = !_showPass),
                            child: Icon(
                              _showPass
                                  ? PhosphorIconsRegular.eyeSlash
                                  : PhosphorIconsRegular.eye,
                              color: AppColors.muted, size: 20,
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loginEmail(),
                        ),

                        // Forgot
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/forgot-password'),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36)),
                            child: Text('Forgot password?',
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.steelBlue)),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Primary button
                        AppButton(
                          label: 'Sign In',
                          loading: auth.loading,
                          onPressed: _loginEmail,
                        ),

                        const SizedBox(height: 20),

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

                        const SizedBox(height: 18),

                        // Google button
                        _GoogleButton(
                            loading: auth.loading,
                            onPressed: _loginGoogle),

                        const SizedBox(height: 24),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.muted)),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/register'),
                              child: Text('Create one',
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

    // Top-right gradient circle
    paint.color = AppColors.steelBlue.withAlpha(18);
    canvas.drawCircle(Offset(size.width + 40, -60), 200, paint);

    // Bottom-left circle
    paint.color = AppColors.deepOcean.withAlpha(180);
    canvas.drawCircle(Offset(-60, size.height * 0.7), 160, paint);

    // Dot grid
    final dotPaint = Paint()
      ..color = AppColors.steelBlue.withAlpha(16)
      ..style = PaintingStyle.fill;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height * 0.45; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => false;
}

// ── Google sign-in button ─────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});
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
            const _GoogleLogo(size: 22),
            const SizedBox(width: 12),
            Text('Continue with Google',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      );
}

class _GoogleLogoPainter extends CustomPainter {
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
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18;
    const double startAngles = -0.2;
    final sweeps = [1.65, 1.57, 1.57, 1.57];
    double start = startAngles;
    for (int i = 0; i < 4; i++) {
      p.color = colours[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        start, sweeps[i], false, p,
      );
      start += sweeps[i];
    }
    final cutPaint = Paint()
      ..color = AppColors.cardElevated
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - size.height * 0.18, r, size.height * 0.36),
        cutPaint);
    final armPaint = Paint()
      ..color = colours[0]
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - size.height * 0.18, r * 0.85, size.height * 0.36),
        armPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
