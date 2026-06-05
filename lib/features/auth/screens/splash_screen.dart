import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
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
    // Rydr exact: white bg, Spacer, FadeIn(1500ms) logo 106×33, Spacer,
    // FadeInUp(500ms) Ripple.gif 83×83, SizedBox(40)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Rydr: FadeIn(1500ms) > Align(center) > Container(w:106,h:33) logo
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 106,
                height: 33,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(RydrAssets.splash),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Rydr: FadeInUp(500ms) > Align(center) > Container(w:83,h:83) Ripple.gif
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 83,
                height: 83,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(RydrAssets.ripple),
                  ),
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
