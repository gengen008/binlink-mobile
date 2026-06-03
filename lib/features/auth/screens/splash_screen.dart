import 'package:flutter/material.dart';
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );

    _ctrl.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      context.read<AuthProvider>().initialize(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (auth.status == AuthStatus.authenticated) {
      final user = auth.user!;
      if (user.isCollector) {
        Navigator.pushReplacementNamed(context, '/collector');
      } else {
        Navigator.pushReplacementNamed(context, '/household');
      }
    } else {
      // Household: show onboarding on first ever launch
      final showOnboarding = await shouldShowOnboarding();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        showOnboarding ? '/onboarding' : '/login',
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.steelBlue.withAlpha(90),
                            blurRadius: 32, spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'BL',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 36, fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Wordmark
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(FlavorConfig.appName, style: AppTextStyles.h1),
                        const SizedBox(height: 6),
                        Text(
                          FlavorConfig.tagline,
                          style: AppTextStyles.body.copyWith(color: AppColors.skyBlue),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 64),

                // Loading dots
                FadeTransition(
                  opacity: _fadeAnim,
                  child: const _LoadingDots(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value + i * 0.33) % 1.0;
            final opacity = (0.3 + (phase < 0.5 ? phase * 2 : (1 - phase) * 2) * 0.7).clamp(0.3, 1.0);
            return Container(
              width: 7, height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.steelBlue.withAlpha((opacity * 255).round()),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
