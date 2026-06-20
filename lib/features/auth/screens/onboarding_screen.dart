import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/design_system/collector_design_system.dart';
import '../../../core/design_system/household_design_system.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final collector = FlavorConfig.isCollector;
    final pages = collector ? _collectorPages : _householdPages;
    return Scaffold(
      backgroundColor: collector ? CollectorColors.dark : HouseholdColors.sand,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip', style: collector ? CollectorType.caption : HouseholdType.caption),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (v) => setState(() => _page = v),
                itemBuilder: (_, i) => _OnboardingPanel(data: pages[i], collector: collector),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: active ? 30 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: collector ? (active ? CollectorColors.green : CollectorColors.line) : (active ? HouseholdColors.primary : const Color(0xFFE1DDD5)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  collector
                      ? CButton(label: _page == pages.length - 1 ? 'START DRIVING' : 'NEXT', onPressed: _next)
                      : HButton(label: _page == pages.length - 1 ? 'Get started' : 'Next', onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    final last = _page == (FlavorConfig.isCollector ? _collectorPages.length : _householdPages.length) - 1;
    if (last) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }
}

class _OnboardingData {
  const _OnboardingData(this.title, this.copy, this.asset);
  final String title;
  final String copy;
  final String asset;
}

const _householdPages = [
  _OnboardingData('Clean pickups, without calls', 'Book, pay, and track verified collectors from a warm map-first experience.', HouseholdAssets.cleanCity),
  _OnboardingData('Choose the bin that fits', 'Select waste type, bin size, schedule, address, and payment in a few taps.', HouseholdAssets.bookPickup),
  _OnboardingData('Track collectors live', 'See ETA, pickup route, and completion status as your request moves.', HouseholdAssets.trackCollectors),
  _OnboardingData('Earn with every pickup', 'Build eco points, rewards, and a cleaner city from your household routine.', HouseholdAssets.earnRewards),
];

const _collectorPages = [
  _OnboardingData('Professional field operations', 'Go online, receive jobs, navigate routes, and complete work from one focused cockpit.', CollectorAssets.welcome),
  _OnboardingData('Earn from every route', 'Track income, bonuses, withdrawals, distance, ratings, and completed jobs.', CollectorAssets.earnMoney),
  _OnboardingData('Move faster with maps', 'A dark operational map keeps pickup, landfill, fuel, and warehouse actions clear.', CollectorAssets.navigateRoutes),
  _OnboardingData('Complete jobs with proof', 'Capture photos, weights, status changes, and completion with large touch targets.', CollectorAssets.completePickups),
];

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({required this.data, required this.collector});
  final _OnboardingData data;
  final bool collector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          Expanded(child: data.asset.endsWith('.svg')
              ? SvgPicture.asset(data.asset, fit: BoxFit.contain)
              : Image.asset(data.asset, fit: BoxFit.contain)),
          const SizedBox(height: 18),
          Text(data.title, textAlign: TextAlign.center, style: collector ? CollectorType.hero : HouseholdType.hero),
          const SizedBox(height: 14),
          Text(data.copy, textAlign: TextAlign.center, style: collector ? CollectorType.body.copyWith(color: const Color(0xFFC8D0DA)) : HouseholdType.body.copyWith(color: HouseholdColors.gray)),
        ],
      ),
    );
  }
}
