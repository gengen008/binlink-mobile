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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Rydr: FadeIn(1500ms) > Center(Container(w:105, h:33, alignment:center, logo image))
          // BinLink: same 105×33 dimensions, BL icon as logo
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Center(
              child: Container(
                width: 105,
                height: 33,
                alignment: Alignment.center,
                child: Container(
                  width: 33,
                  height: 33,
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
