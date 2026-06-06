import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
  final IconData icon;
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
    icon: PhosphorIconsLight.trashSimple,
    heading: 'Clean Cities\nStart Here',
    body: 'BinLink connects your home to trusted\ncollectors for a cleaner Ghana.',
    accent: AppColors.steelBlue,
  ),
  _Page(
    icon: PhosphorIconsLight.calendarCheck,
    heading: 'Book in Seconds',
    body: 'Request a same-day pickup or schedule\nahead — we work around your timing.',
    accent: Color(0xFF0EA5E9),
  ),
  _Page(
    icon: PhosphorIconsLight.navigationArrow,
    heading: 'Track Live',
    body: 'Real-time GPS tracking. Know exactly\nwhen your collector will arrive.',
    accent: AppColors.skyBlue,
  ),
  _Page(
    icon: PhosphorIconsLight.leaf,
    heading: 'Earn Eco Rewards',
    body: 'Every recyclable pickup earns points.\nRedeem them for discounts on bookings.',
    accent: Color(0xFF16A34A),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: logo + brand + skip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      AppAssets.logo,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BinLink',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const Spacer(),
                  if (_current < _pages.length - 1)
                    GestureDetector(
                      onTap: _done,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Icon — outer ring + inner fill circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: pg.accent.withAlpha(18),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: pg.accent.withAlpha(35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                pg.icon,
                                size: 52,
                                color: pg.accent,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 44),

                        // Heading
                        Text(
                          pg.heading,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.secondary,
                            fontSize: 28,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          pg.body,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.muted,
                            height: 1.65,
                            fontSize: 15,
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
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
                        : AppColors.border,
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
                          child: _OutlineBtn(onTap: _done),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _FilledBtn(
                            accent: page.accent,
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),
            ),

            const SafeArea(top: false, child: SizedBox(height: 20)),
          ],
        ),
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 6),
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
  const _FilledBtn({required this.accent, required this.onTap});
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
              color: accent.withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
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
  const _OutlineBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'Skip',
            style: AppTextStyles.button.copyWith(
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
