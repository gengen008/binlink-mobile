import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_radius.dart';
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

class _Page {
  final String asset;
  final String heading;
  final String body;
  const _Page({required this.asset, required this.heading, required this.body});
}

const _pages = [
  _Page(
    asset: AppAssets.pickupMarker,
    heading: 'Book a pickup from your address',
    body: 'Enter your location, choose waste type and bin size. Request a same-day pickup or schedule ahead.',
  ),
  _Page(
    asset: AppAssets.truck,
    heading: 'Track collector arrival in real time',
    body: 'See your assigned collector on the map. Get live ETA updates and call or chat directly.',
  ),
  _Page(
    asset: AppAssets.cash,
    heading: 'Pay and manage your pickup history',
    body: 'View receipts, track spending, and manage scheduled pickups — all in one place.',
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text('BinLink', style: AppTextStyles.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(onPressed: _done, child: Text('Skip', style: AppTextStyles.meta)),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: _current == i ? AppColors.primary : AppColors.border, borderRadius: AppRadius.fullBR),
                    )),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_current == _pages.length - 1) {
                        _done();
                      } else {
                        _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                    child: Text(_current == _pages.length - 1 ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.mdBR),
            child: SvgPicture.asset(page.asset, height: 64, colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn)),
          ),
          const SizedBox(height: 40),
          Text(page.heading, style: AppTextStyles.display.copyWith(fontSize: 24)),
          const SizedBox(height: 16),
          Text(page.body, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
