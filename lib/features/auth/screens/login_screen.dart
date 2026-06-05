// Rydr choose_auth.dart / sign_in.dart — literal transplant.
//
// Rydr source structure:
//   Scaffold(backgroundColor: Primarywhite) > SafeArea > FadeInDown(3000ms) >
//   SingleChildScrollView > Column([
//     YMargin(100), authHeader(context), YMargin(30),
//     FadeInDown(1400ms, Padding(h:30, Column([title, subtitle, fields, button]))),
//     YMargin(40), FadeInDown(2000ms, GoogleButton),
//     YMargin(40), FadeInDown(2200ms, Row("Have an account?")),
//   ])
//
// BinLink replacements only:
//   - Primarywhite → Colors.white
//   - signIn() → auth.loginWithEmail / loginWithGoogle
//   - route push → FlavorConfig routes
//   - authimage1 → authHeader() eco cards

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../components/auth_header.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/rydr_assets.dart';
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
    // Rydr: Scaffold(backgroundColor: ColorPath.Primarywhite)
    return Scaffold(
      backgroundColor: Colors.white,
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
                // Rydr: YMargin(100)
                const SizedBox(height: 100),

                // Rydr: authHeader(context) — FadeInDown(1500ms) logo + illustration
                authHeader(context),

                // Rydr: FadeInDown(1400ms, Padding(h:30, Column([...])))
                const SizedBox(height: 30),
                FadeInDown(
                  duration: const Duration(milliseconds: 1400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rydr: Text("Welcome Back To Rydr", montserrat, 18, w500, Primarydark)
                        Text(
                          FlavorConfig.isCollector
                              ? 'Welcome Back, Collector'
                              : 'Welcome Back To BinLink',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2421),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 7),
                        // Rydr: Text("Enjoy awesome rides...", montserrat, 12, w300, Primarydark)
                        Text(
                          FlavorConfig.isCollector
                              ? 'Sign in to your collector account'
                              : 'Book waste pickups at affordable rates',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF1F2421),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Rydr: CustomTextFieldWidget(hintText: 'Email Address')
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
                          fillColor: const Color(0xFFF5F6F5),
                          textColor: AppColors.midnightNavy,
                          labelColor: AppColors.midnightNavy,
                        ),
                        const SizedBox(height: 10),

                        // Rydr: CustomTextFieldWidget(hideText: true, suffixWidget: Text("show"))
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
                          fillColor: const Color(0xFFF5F6F5),
                          textColor: AppColors.midnightNavy,
                          labelColor: AppColors.midnightNavy,
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

                        // Rydr: Container(h:50, sw, br:8, Primarydark, InkWell("Sign In"))
                        AppButton(
                          label: 'Sign In',
                          loading: auth.loading,
                          onPressed: _loginEmail,
                        ),
                      ],
                    ),
                  ),
                ),

                // Rydr: YMargin(40), FadeInDown(2000ms, GoogleButton)
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

                // Rydr: YMargin(40), FadeInDown(2200ms, Row("Have an account? Sign up"))
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 2200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Sign up',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.black,
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

// ── Google sign-in button — exact Rydr layout ────────────────────────────────
// Rydr: Container(h:50, sw-180, white, br:8, border:Color(0xFF90D8FF))
//   > Row(center) [Text("Continue with Google"), XMargin(7), SvgPicture(google.svg)]

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 50,
        width: sw - 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFF90D8FF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue with Google',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF212F20),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 7),
              SvgPicture.asset(RydrAssets.google),
            ],
          ),
        ),
      ),
    );
  }
}
