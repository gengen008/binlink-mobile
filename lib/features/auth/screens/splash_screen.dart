// Trippo exact: Scaffold(dark) > centered bold app name on dark bg.
// BinLink: secondary (#0F172A) scaffold + logo circle + name + Lottie eco animation.

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/rydr_assets.dart';
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
      backgroundColor: AppColors.secondary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Trippo: centered bold app name; BinLink: logo circle + name
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Column(
              children: [
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Image.asset(RydrAssets.logo, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'BinLink',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Eco Waste Collection',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Lottie eco animation at bottom
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Lottie.asset(
              RydrAssets.lottieSplash,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),

          const SafeArea(
            top: false,
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}
