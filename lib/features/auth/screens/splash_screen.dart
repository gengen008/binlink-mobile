// BinLink splash: dark scaffold + logo circle + name + pulsing eco loading ring.

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initApp();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
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

          // Logo circle + app name
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
                      child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
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
                      AppTextStyles.bodySmall.copyWith(color: AppColors.primaryMid),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Pulsing eco ring — indicates loading without a broken Lottie
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Opacity(
                opacity: _pulse.value,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
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
