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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _showPass    = false;

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
    if (user.isPending) {
      Navigator.pushReplacementNamed(context, '/pending');
    } else if (user.isCollector) {
      Navigator.pushReplacementNamed(context, '/collector');
    } else {
      Navigator.pushReplacementNamed(context, '/household');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
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

                  // Logo mark
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

                  // Email
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: const Icon(PhosphorIconsRegular.envelope, color: AppColors.muted, size: 20),
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  AppTextField(
                    controller: _passCtrl,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: !_showPass,
                    autofillHints: const [AutofillHints.password],
                    prefixIcon: const Icon(PhosphorIconsRegular.lock, color: AppColors.muted, size: 20),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _showPass = !_showPass),
                      child: Icon(
                        _showPass ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                        color: AppColors.muted, size: 20,
                      ),
                    ),
                    validator: Validators.password,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _loginEmail(),
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

                  const SizedBox(height: 20),

                  AppButton(
                    label: 'Sign In',
                    loading: auth.loading,
                    onPressed: _loginEmail,
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign-In
                  _GoogleButton(
                    loading: auth.loading,
                    onPressed: _loginGoogle,
                  ),

                  const SizedBox(height: 28),

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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo in brand colours
            const _GoogleLogo(size: 22),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Draw coloured arcs to approximate Google logo
    final colours = [
      const Color(0xFF4285F4), // blue  — right
      const Color(0xFF34A853), // green — bottom
      const Color(0xFFFBBC05), // yellow — left
      const Color(0xFFEA4335), // red   — top
    ];

    final Paint p = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18;
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

    // White cutout for the "G" arm (right side)
    final cutPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.18, r, size.height * 0.36),
      cutPaint,
    );
    final armPaint = Paint()
      ..color = colours[0]
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.18, r * 0.85, size.height * 0.36),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
