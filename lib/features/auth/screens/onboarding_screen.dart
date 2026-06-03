import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const String _kOnboardingSeenKey = 'onboarding_seen_v3';

/// Call once on app start (household flavor only) to check if onboarding
/// has been shown. Returns true if onboarding should be shown.
Future<bool> shouldShowOnboarding() async {
  if (!FlavorConfig.isHousehold) return false;
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kOnboardingSeenKey) ?? false);
}

/// Mark onboarding as completed so it never shows again.
Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSeenKey, true);
}

// ── Page data ────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String heading;
  final String subtitle;
  final Color accentColor;
  final _IllustrationBuilder illustration;

  const _OnboardingPage({
    required this.heading,
    required this.subtitle,
    required this.accentColor,
    required this.illustration,
  });
}

typedef _IllustrationBuilder = Widget Function();

final List<_OnboardingPage> _pages = [
  const _OnboardingPage(
    heading: 'Clean Cities\nStart Here',
    subtitle:
        'BinLink connects households with trusted\ncollectors for a cleaner Ghana.',
    accentColor: AppColors.steelBlue,
    illustration: _buildCityIllustration,
  ),
  const _OnboardingPage(
    heading: 'Pick Up On\nYour Schedule',
    subtitle:
        'Book same-day pickups or schedule ahead.\nWe work around your timing.',
    accentColor: AppColors.skyBlue,
    illustration: _buildScheduleIllustration,
  ),
  const _OnboardingPage(
    heading: 'Get Rewarded\nfor Recycling',
    subtitle:
        'Earn Eco Points every time you recycle.\nRedeem for discounts on future pickups.',
    accentColor: AppColors.success,
    illustration: _buildRewardsIllustration,
  ),
  const _OnboardingPage(
    heading: 'Watch Your\nCollector Live',
    subtitle:
        'Real-time GPS tracking. Know exactly\nwhen your collector will arrive.',
    accentColor: AppColors.warning,
    illustration: _buildTrackingIllustration,
  ),
];

// ── Illustrations ─────────────────────────────────────────────────────────────

Widget _buildCityIllustration() {
  return SizedBox(
    width: 260,
    height: 260,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.steelBlue.withAlpha(18),
            border: Border.all(color: AppColors.steelBlue.withAlpha(40), width: 1.5),
          ),
        ),
        // Inner circle
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepOcean, AppColors.surface],
            ),
            border: Border.all(color: AppColors.steelBlue.withAlpha(80), width: 2),
          ),
          child: const Icon(
            PhosphorIconsFill.buildings,
            color: AppColors.steelBlue,
            size: 64,
          ),
        ),
        // Leaf top-right
        Positioned(
          top: 24, right: 20,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withAlpha(30),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: const Icon(PhosphorIconsFill.leaf, color: AppColors.success, size: 22),
          ),
        ),
        // Sparkle bottom-left
        Positioned(
          bottom: 28, left: 16,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iceBlue.withAlpha(25),
              border: Border.all(color: AppColors.iceBlue.withAlpha(60)),
            ),
            child: const Icon(PhosphorIconsFill.sparkle, color: AppColors.iceBlue, size: 20),
          ),
        ),
        // Bin bottom-right
        Positioned(
          bottom: 20, right: 24,
          child: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.steelBlue, AppColors.skyBlue],
              ),
            ),
            child: const Icon(PhosphorIconsFill.trashSimple, color: AppColors.white, size: 24),
          ),
        ),
      ],
    ),
  );
}

Widget _buildScheduleIllustration() {
  return SizedBox(
    width: 260,
    height: 260,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.skyBlue.withAlpha(18),
            border: Border.all(color: AppColors.skyBlue.withAlpha(40), width: 1.5),
          ),
        ),
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepOcean, AppColors.surface],
            ),
            border: Border.all(color: AppColors.skyBlue.withAlpha(80), width: 2),
          ),
          child: const Icon(PhosphorIconsFill.calendarCheck, color: AppColors.skyBlue, size: 64),
        ),
        Positioned(
          top: 22, left: 22,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withAlpha(30),
              border: Border.all(color: AppColors.warning.withAlpha(80)),
            ),
            child: const Icon(PhosphorIconsFill.lightning, color: AppColors.warning, size: 22),
          ),
        ),
        Positioned(
          top: 28, right: 18,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iceBlue.withAlpha(25),
              border: Border.all(color: AppColors.iceBlue.withAlpha(60)),
            ),
            child: const Icon(PhosphorIconsFill.clock, color: AppColors.iceBlue, size: 20),
          ),
        ),
        Positioned(
          bottom: 22, left: 20,
          child: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.skyBlue, AppColors.iceBlue],
              ),
            ),
            child: const Icon(PhosphorIconsFill.truck, color: AppColors.white, size: 24),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRewardsIllustration() {
  return SizedBox(
    width: 260,
    height: 260,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withAlpha(18),
            border: Border.all(color: AppColors.success.withAlpha(40), width: 1.5),
          ),
        ),
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepOcean, AppColors.surface],
            ),
            border: Border.all(color: AppColors.success.withAlpha(80), width: 2),
          ),
          child: const Icon(PhosphorIconsFill.coins, color: AppColors.success, size: 64),
        ),
        Positioned(
          top: 20, right: 22,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withAlpha(30),
              border: Border.all(color: AppColors.warning.withAlpha(80)),
            ),
            child: const Icon(PhosphorIconsFill.star, color: AppColors.warning, size: 22),
          ),
        ),
        Positioned(
          bottom: 24, right: 20,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iceBlue.withAlpha(25),
              border: Border.all(color: AppColors.iceBlue.withAlpha(60)),
            ),
            child: const Icon(PhosphorIconsFill.recycle, color: AppColors.iceBlue, size: 20),
          ),
        ),
        Positioned(
          bottom: 20, left: 22,
          child: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.success, Color(0xFF16A34A)],
              ),
            ),
            child: const Icon(PhosphorIconsFill.gift, color: AppColors.white, size: 24),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTrackingIllustration() {
  return SizedBox(
    width: 260,
    height: 260,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withAlpha(18),
            border: Border.all(color: AppColors.warning.withAlpha(40), width: 1.5),
          ),
        ),
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepOcean, AppColors.surface],
            ),
            border: Border.all(color: AppColors.warning.withAlpha(80), width: 2),
          ),
          child: const Icon(PhosphorIconsFill.mapTrifold, color: AppColors.warning, size: 64),
        ),
        Positioned(
          top: 20, left: 22,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger.withAlpha(30),
              border: Border.all(color: AppColors.danger.withAlpha(80)),
            ),
            child: const Icon(PhosphorIconsFill.mapPin, color: AppColors.danger, size: 22),
          ),
        ),
        Positioned(
          top: 26, right: 18,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.steelBlue.withAlpha(30),
              border: Border.all(color: AppColors.steelBlue.withAlpha(80)),
            ),
            child: const Icon(PhosphorIconsFill.navigationArrow, color: AppColors.steelBlue, size: 20),
          ),
        ),
        Positioned(
          bottom: 22, right: 20,
          child: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.warning, Color(0xFFD97706)],
              ),
            ),
            child: const Icon(PhosphorIconsFill.truck, color: AppColors.white, size: 24),
          ),
        ),
      ],
    ),
  );
}

// ── Main screen ───────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animCtrl.forward(from: 0);
  }

  Future<void> _finish() async {
    await markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Page content ─────────────────────────────────────────
              PageView.builder(
                controller: _pageCtrl,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPageView(
                  page: _pages[i],
                  fadeAnimation: _fadeAnim,
                  isCurrent: i == _currentPage,
                ),
              ),

              // ── Skip button ──────────────────────────────────────────
              if (!isLast)
                Positioned(
                  top: 12, right: 20,
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Skip',
                      style: AppTextStyles.label.copyWith(color: AppColors.muted),
                    ),
                  ),
                ),

              // ── Bottom controls ──────────────────────────────────────
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == _currentPage
                                  ? page.accentColor
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Next / Get Started button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                page.accentColor,
                                page.accentColor.withAlpha(200),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: page.accentColor.withAlpha(80),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? 'Get Started' : 'Next',
                                style: AppTextStyles.button,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLast
                                    ? PhosphorIconsRegular.arrowRight
                                    : PhosphorIconsRegular.arrowRight,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sign in link
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          ),
                          GestureDetector(
                            onTap: _finish,
                            child: Text(
                              'Sign In',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.skyBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual page view ──────────────────────────────────────────────────────

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.page,
    required this.fadeAnimation,
    required this.isCurrent,
  });

  final _OnboardingPage page;
  final Animation<double> fadeAnimation;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          FadeTransition(
            opacity: fadeAnimation,
            child: page.illustration(),
          ),

          const SizedBox(height: 48),

          // Heading
          FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(fadeAnimation),
              child: Text(
                page.heading,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 30,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          FadeTransition(
            opacity: fadeAnimation,
            child: Text(
              page.subtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
