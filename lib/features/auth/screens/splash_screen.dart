import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      context.read<AuthProvider>().initialize(),
      Future.delayed(const Duration(milliseconds: 2400)),
    ]);
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else {
      final showOnboarding = await shouldShowOnboarding();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        showOnboarding ? '/onboarding' : '/login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // ── Logo wordmark (Rydr: FadeIn 1500ms centered logo image) ──────────
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.steelBlue.withAlpha(100),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'BL',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    FlavorConfig.appName,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FlavorConfig.tagline,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Bottom eco-pulse ring (Rydr: FadeInUp 500ms ripple image) ────────
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 83,
                height: 83,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.steelBlue.withAlpha(80),
                    width: 2,
                  ),
                  color: AppColors.steelBlue.withAlpha(15),
                ),
                child: Icon(
                  PhosphorIconsRegular.recycle,
                  color: AppColors.steelBlue.withAlpha(140),
                  size: 36,
                ),
              ),
            ),
          ),

          const SafeArea(
            top: false,
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}
