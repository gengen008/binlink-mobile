import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
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
  final IconData icon;
  final String label;
  final String heading;
  final String body;
  const _Page({
    required this.icon,
    required this.label,
    required this.heading,
    required this.body,
  });
}

const _pages = [
  _Page(
    icon: PhosphorIconsRegular.mapPin,
    label: 'Book',
    heading: 'Book a pickup\nfrom your address',
    body: 'Enter your location, choose waste type and bin size. Request a same-day pickup or schedule ahead.',
  ),
  _Page(
    icon: PhosphorIconsRegular.navigationArrow,
    label: 'Track',
    heading: 'Track collector\narrival in real time',
    body: 'See your assigned collector on the map. Get live ETA updates and call or chat directly.',
  ),
  _Page(
    icon: PhosphorIconsRegular.receipt,
    label: 'Manage',
    heading: 'Pay and manage\nyour pickup history',
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

  void _next() {
    if (_current == _pages.length - 1) {
      _done();
    } else {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
              child: Row(
                children: [
                  Text('BinLink',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      )),
                  const Spacer(),
                  if (_current < _pages.length - 1)
                    GestureDetector(
                      onTap: _done,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Text('Skip',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.muted)),
                      ),
                    ),
                ],
              ),
            ),

            // Step indicator bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(_pages.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < _pages.length - 1 ? 6 : 0),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _current
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _current == _pages.length - 1
                            ? 'Get started'
                            : 'Continue',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                  if (_current < _pages.length - 1) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _done,
                      child: Text('Skip setup',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.muted)),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in a contained square — no decorative orbs
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(page.icon, color: AppColors.primary, size: 32),
          ),

          const SizedBox(height: 32),

          Text(
            page.heading,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.secondary,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            page.body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
