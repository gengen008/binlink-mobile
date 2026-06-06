import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/rydr_assets.dart';

const String _kOnboardingSeenKey = 'onboarding_seen_v3';

Future<bool> shouldShowOnboarding() async {
  if (!FlavorConfig.isHousehold) return false;
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kOnboardingSeenKey) ?? false);
}

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSeenKey, true);
}

// ── Page data ──────────────────────────────────────────────────────────────────

class _Page {
  final String icon;
  final String heading;
  final String body;
  final Color accent;
  const _Page({
    required this.icon,
    required this.heading,
    required this.body,
    required this.accent,
  });
}

const _pages = [
  _Page(
    icon: RydrAssets.globe,
    heading: 'Clean Cities\nStart Here',
    body: 'BinLink connects your home to trusted\ncollectors for a cleaner Ghana.',
    accent: AppColors.steelBlue,
  ),
  _Page(
    icon: RydrAssets.stopwatch,
    heading: 'Book in Seconds',
    body: 'Request a same-day pickup or schedule\nahead. We work around your timing.',
    accent: AppColors.success,
  ),
  _Page(
    icon: RydrAssets.locate,
    heading: 'Track Live',
    body: 'Real-time GPS tracking. Know exactly\nwhen your collector will arrive.',
    accent: AppColors.skyBlue,
  ),
  _Page(
    icon: RydrAssets.cash,
    heading: 'Earn Eco Rewards',
    body: 'Every recyclable pickup earns points.\nRedeem them for discounts on bookings.',
    accent: Color(0xFF34D399),
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final nav = Navigator.of(context);
    await markOnboardingSeen();
    if (!mounted) return;
    nav.pushReplacementNamed('/login');
  }

  Future<void> _next() async {
    if (_current == _pages.length - 1) {
      await _done();
    } else {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          // ── City background at very low opacity ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(RydrAssets.citybg, fit: BoxFit.cover),
            ),
          ),

          // ── Dark gradient (bottom-heavy) ensures text is always readable ──
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xBB021024),
                    AppColors.secondary,
                  ],
                  stops: [0.0, 0.30, 0.65],
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Top bar: logo + brand name + skip ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
                  child: Row(
                    children: [
                      ClipOval(
                        child: ColoredBox(
                          color: AppColors.primary.withAlpha(40),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              RydrAssets.logo,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BinLink',
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      if (_current < _pages.length - 1)
                        GestureDetector(
                          onTap: _done,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withAlpha(40)),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── PageView ──
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) {
                      final pg = _pages[i];
                      return Column(
                        children: [
                          const Spacer(flex: 2),

                          // Icon — double circle with accent tint
                          Container(
                            width: 148,
                            height: 148,
                            decoration: BoxDecoration(
                              color: pg.accent.withAlpha(30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: pg.accent.withAlpha(60),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: pg.accent.withAlpha(55),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(24),
                                child: SvgPicture.asset(
                                  pg.icon,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Heading
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Text(
                              pg.heading,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                fontSize: 27,
                                height: 1.25,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 44),
                            child: Text(
                              pg.body,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withAlpha(180),
                                height: 1.65,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),
                        ],
                      );
                    },
                  ),
                ),

                // ── Dot indicators ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final sel = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: sel ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sel
                            ? page.accent
                            : Colors.white.withAlpha(55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // ── Bottom buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _current == _pages.length - 1
                      ? _GetStartedButton(accent: page.accent, onTap: _done)
                      : Row(
                          children: [
                            Expanded(
                              child: _OutlineBtn(label: 'Skip', onTap: _done),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _FilledBtn(
                                label: 'Next',
                                accent: page.accent,
                                onTap: _next,
                              ),
                            ),
                          ],
                        ),
                ),

                const SafeArea(top: false, child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Button widgets ─────────────────────────────────────────────────────────────

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(80),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(
              PhosphorIconsBold.arrowRight,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({
    required this.label,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(65),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Icon(
              PhosphorIconsRegular.arrowRight,
              color: Colors.white,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(45)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: Colors.white.withAlpha(180),
            ),
          ),
        ),
      ),
    );
  }
}
