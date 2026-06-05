import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
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
    // Rydr: white background, minimal — FadeIn(1500ms) logo, Spacer, FadeInUp(500ms) pulse ring
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Spacer(),

          // ── Logo (Rydr: FadeIn 1500ms, centered 105×33 logo image) ───────────
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Center(
              child: Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.steelBlue.withAlpha(60),
                      blurRadius: 32,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'BL',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Eco-pulse ring (Rydr: FadeInUp 500ms, 83×83 ripple image) ────────
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: 83,
              height: 83,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.steelBlue.withAlpha(120),
                  width: 2,
                ),
                color: AppColors.steelBlue.withAlpha(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.recycle,
                color: AppColors.steelBlue,
                size: 36,
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
