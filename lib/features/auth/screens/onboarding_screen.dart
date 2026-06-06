import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

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
  final String asset;
  final String heading;
  final String body;
  final Color bgColor;
  const _Page({required this.asset, required this.heading, required this.body, required this.bgColor});
}

const _pages = [
  _Page(
    asset: AppAssets.onboarding1,
    heading: 'Book a pickup from your address',
    body: 'Enter your location, choose waste type and bin size. Request a same-day pickup or schedule ahead.',
    bgColor: Color(0xFFEFF6FF), // Light blue tint
  ),
  _Page(
    asset: AppAssets.onboarding2,
    heading: 'Track collector arrival in real time',
    body: 'See your assigned collector on the map. Get live ETA updates and call or chat directly.',
    bgColor: Color(0xFFE0F2FE),
  ),
  _Page(
    asset: AppAssets.onboarding3,
    heading: 'Pay and manage your pickup history',
    body: 'View receipts, track spending, and manage scheduled pickups — all in one place.',
    bgColor: Color(0xFFF3F4F6),
  ),
  _Page(
    asset: AppAssets.onboarding4,
    heading: 'Earn Eco Rewards for recycling',
    body: 'Get points for every kg of recycled waste. Trade points for discounts and plant trees.',
    bgColor: Color(0xFFFEF3C7),
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

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background Tint (Top 60%) ─────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: MediaQuery.of(context).size.height * 0.6,
            width: double.infinity,
            color: page.bgColor,
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Text('BinLink', style: AppTextStyles.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      TextButton(
                        onPressed: _done, 
                        child: Text('Skip', style: AppTextStyles.meta.copyWith(color: AppColors.textPrimary))
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) => _OnboardingContent(page: _pages[i]),
                  ),
                ),

                // ── Bottom Sheet Area (40% height) ──────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _current == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _current == i ? AppColors.primary : AppColors.border, 
                            borderRadius: AppRadius.fullBR
                          ),
                        )),
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: _current == _pages.length - 1 ? 'Get Started' : 'Continue',
                        onPressed: () {
                          if (_current == _pages.length - 1) {
                            _done();
                          } else {
                            _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutExpo);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Center(
          child: SvgPicture.asset(page.asset, height: 260),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(page.heading, style: AppTextStyles.display.copyWith(fontSize: 26)),
              const SizedBox(height: 16),
              Text(page.body, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 40), // Gap before the white sheet starts
      ],
    );
  }
}
