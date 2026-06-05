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
              children: [
                // ── Top margin (Rydr: YMargin(100)) ────────────────────────────
                const SizedBox(height: 60),

                // ── Auth header (Rydr: authHeader widget) ───────────────────────
                const _BinLinkAuthHeader(),

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
                        // Title (Rydr: "Welcome Back To Rydr" Montserrat w500 18)
                        Text(
                          FlavorConfig.isCollector
                              ? 'Welcome Back, Collector'
                              : 'Welcome Back',
                          style: AppTextStyles.h2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 7),
                        // Subtitle (Rydr: "Enjoy awesome rides..." Montserrat w300 12)
                        Text(
                          FlavorConfig.isCollector
                              ? 'Sign in to your collector account'
                              : 'Sign in to book waste pickups',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Email (Rydr: CustomTextFieldWidget hintText: 'Email Address')
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

                        // Password (Rydr: hideText: true, suffixWidget: Text("show"))
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: !_showPass,
                          autofillHints: const [AutofillHints.password],
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
                          onFieldSubmitted: (_) => _loginEmail(),
                        ),
                        const SizedBox(height: 10),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, '/forgot-password'),
                            child: Text(
                              'Forgot password?',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.steelBlue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Primary button (Rydr: dark filled, full-width, rounded 8)
                        AppButton(
                          label: 'Sign In',
                          loading: auth.loading,
                          onPressed: _loginEmail,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Google button row (Rydr: FadeInDown 2000ms, Google + Facebook + Touch) ──
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 2000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: _GoogleButton(
                      loading: auth.loading,
                      onPressed: _loginGoogle,
                    ),
                  ),
                ),

                // ── Register link (Rydr: FadeInDown 2200ms, "Have an account?") ──
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 2200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Sign up',
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

// ── BinLink auth header (Rydr: authHeader widget — logo + illustration) ───────

class _BinLinkAuthHeader extends StatelessWidget {
  const _BinLinkAuthHeader();

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 1500),
      child: Column(
        children: [
          // Logo (Rydr: centered 105x33 image → BinLink: BL wordmark)
          Center(
            child: Row(
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
          ),
          const SizedBox(height: 30),

          // Illustration (Rydr: full-width 160px car image → BinLink: eco icons row)
          const SizedBox(
            width: double.infinity,
            height: 160,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 30),
                physics: NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _EcoItem(
                      icon: PhosphorIconsFill.trashSimple,
                      label: 'Household',
                      time: '30 GHC',
                      color: AppColors.steelBlue,
                    ),
                    SizedBox(width: 8),
                    _EcoItem(
                      icon: PhosphorIconsFill.recycle,
                      label: 'Plastic',
                      time: '30 GHC',
                      color: AppColors.success,
                    ),
                    SizedBox(width: 8),
                    _EcoItem(
                      icon: PhosphorIconsFill.leaf,
                      label: 'Organic',
                      time: '40 GHC',
                      color: Color(0xFF34D399),
                    ),
                    SizedBox(width: 8),
                    _EcoItem(
                      icon: PhosphorIconsFill.laptop,
                      label: 'E-Waste',
                      time: '50 GHC',
                      color: Color(0xFFA78BFA),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Eco item card (mirrors Rydr's FavoriteItems widget) ───────────────────────

class _EcoItem extends StatelessWidget {
  const _EcoItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String   label;
  final String   time;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 110,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.steelBlue),
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        color: AppColors.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
            height: 67,
            width: 67,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(25),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google sign-in button ──────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});
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
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
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

class _GoogleLogoPainter extends CustomPainter {
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
