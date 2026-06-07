import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';

const String _kOnboardingSeenKey = 'onboarding_seen_v5';

Future<bool> shouldShowOnboarding() async {
  if (!FlavorConfig.isHousehold) return false;
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kOnboardingSeenKey) ?? false);
}

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSeenKey, true);
}

class _Page {
  final String imageAsset;
  final String badgeAsset;
  final Color accentColor;
  final String heading;
  final String body;

  const _Page({
    required this.imageAsset,
    required this.badgeAsset,
    required this.accentColor,
    required this.heading,
    required this.body,
  });
}

const _pages = [
  _Page(
    imageAsset: AppAssets.onboarding1,
    badgeAsset: AppAssets.trashBin,
    accentColor: AppColors.steelBlue,
    heading: 'Book a pickup\nfrom your door',
    body: 'Choose waste type and bin size.\nRequest same-day or schedule ahead.',
  ),
  _Page(
    imageAsset: AppAssets.onboarding2,
    badgeAsset: AppAssets.truck,
    accentColor: Color(0xFF3B82F6),
    heading: 'Track your collector\nin real time',
    body: 'See your assigned collector on the map.\nGet live ETA and communicate directly.',
  ),
  _Page(
    imageAsset: AppAssets.onboarding3,
    badgeAsset: AppAssets.receipt,
    accentColor: AppColors.skyBlue,
    heading: 'Pay cash on\narrival',
    body: 'No upfront payment needed.\nPay your collector directly when they arrive.',
  ),
  _Page(
    imageAsset: AppAssets.onboarding4,
    badgeAsset: AppAssets.leaf,
    accentColor: AppColors.success,
    heading: 'Earn Eco Points\nfor recycling',
    body: 'Get rewarded for every kg of recycled waste.\nRedeem points for discounts.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _current = 0;

  Future<void> _done() async {
    await markOnboardingSeen();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _next() {
    if (_current == _pages.length - 1) {
      _done();
    } else {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final illustrationH = size.height * 0.54;
    final page = _pages[_current];

    return Scaffold(
      backgroundColor: page.accentColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        color: page.accentColor,
        child: Column(
          children: [
            // ── Illustration area (colored background) ─────────────────────
            SizedBox(
              height: illustrationH,
              child: Stack(
                children: [
                  // Subtle radial glow behind illustration
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Colors.white.withAlpha(40),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top row: logo + skip
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.logoSvg,
                            height: 28,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _done,
                            child: Text(
                              'Skip',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withAlpha(200),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // PageView for illustrations
                  Positioned.fill(
                    top: 80,
                    child: PageView.builder(
                      controller: _ctrl,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (_, i) => _IllustrationPanel(page: _pages[i]),
                    ),
                  ),
                ],
              ),
            ),

            // ── White bottom card ──────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        page.heading,
                        key: ValueKey(page.heading),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Body
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        page.body,
                        key: ValueKey(page.body),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Dots + Arrow button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dot indicators
                        Row(
                          children: List.generate(_pages.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 6),
                              width: _current == i ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _current == i ? page.accentColor : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        // Arrow/done button
                        GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: page.accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: page.accentColor.withAlpha(90),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _current == _pages.length - 1
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main SVG illustration
        Center(
          child: Image.asset(
            page.imageAsset,
            height: 260,
            fit: BoxFit.contain,
          ),
        ),
        // PNG badge — floating card bottom-right
        Positioned(
          bottom: 24,
          right: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(page.badgeAsset, width: 32, height: 32),
                const SizedBox(width: 8),
                Text(
                  _badgeLabel(page.badgeAsset),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _badgeLabel(String asset) {
    if (asset.contains('truck')) return 'Live Tracking';
    if (asset.contains('trash-bin')) return 'Book Now';
    if (asset.contains('receipt')) return 'Cash on Arrival';
    if (asset.contains('leaf')) return 'Eco Points';
    return 'BinLink';
  }
}
