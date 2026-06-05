// Rydr register.dart — literal transplant.
//
// Rydr source structure:
//   Scaffold(backgroundColor: Primarywhite) > SafeArea > SingleChildScrollView >
//   Column([
//     YMargin(100), authHeader(context),
//     FadeInDown(1400ms, Padding(h:30, Column([title, subtitle, fields, button]))),
//     YMargin(40), FadeInDown(2000ms, GoogleButton),
//     YMargin(40), FadeInDown(2200ms, Row("Have an account?"))
//   ])
//
// BinLink replacements only:
//   - Primarywhite → Colors.white
//   - registerWithEmail() / loginWithGoogle()
//   - routes → FlavorConfig routes
//   - role badge inserted (BinLink-specific UX)

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rydr: YMargin(100)
                const SizedBox(height: 100),

                // Rydr: authHeader(context)
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
                        Text(
                          'Create Account',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2421),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          FlavorConfig.registerSubtitle,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF1F2421),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 30),

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
                          fillColor: const Color(0xFFF5F6F5),
                          textColor: AppColors.midnightNavy,
                          labelColor: AppColors.midnightNavy,
                        ),
                        const SizedBox(height: 10),

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
                          fillColor: const Color(0xFFF5F6F5),
                          textColor: AppColors.midnightNavy,
                          labelColor: AppColors.midnightNavy,
                        ),
                        const SizedBox(height: 20),

                        AppButton(
                          label: 'Create Account',
                          loading: auth.loading,
                          onPressed: _register,
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
                    child: _GoogleRegisterButton(
                      loading: auth.loading,
                      onPressed: _registerGoogle,
                    ),
                  ),
                ),

                // Rydr: YMargin(40), FadeInDown(2200ms, Row("Have an account?"))
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 2200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
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

// ── Google register button — exact Rydr layout ───────────────────────────────

class _GoogleRegisterButton extends StatelessWidget {
  const _GoogleRegisterButton(
      {required this.loading, required this.onPressed});
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
