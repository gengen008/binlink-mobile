import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import '../../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Clean Cities\nStart Here",
      description: "Join thousands of households making their cities cleaner and greener one pickup at a time.",
      image: AppAssets.onboarding1,
    ),
    OnboardingData(
      title: "Schedule\nPickups Instantly",
      description: "Choose your waste type, select a bin size, and get matched with a collector in seconds.",
      image: AppAssets.onboarding2,
    ),
    OnboardingData(
      title: "Track Your\nImpact Live",
      description: "Follow your collector on the map and see how much waste you've diverted from landfills.",
      image: AppAssets.onboarding3,
    ),
    OnboardingData(
      title: "Connect with\nVerified Experts",
      description: "Our collectors are trained, verified, and ready to handle your waste professionally.",
      image: AppAssets.onboarding4,
    ),
  ];

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background & Content ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: (v) => setState(() => _currentPage = v),
            itemCount: _pages.length,
            itemBuilder: (context, i) {
              return _OnboardingPage(data: _pages[i]);
            },
          ),

          // ── Bottom Controls ──
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // Button
                  AppButton(
                    label: _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _onFinish();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),

                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _onFinish,
                      child: Text(
                        "Skip",
                        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100),
        // Illustration
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: SvgPicture.asset(
              data.image,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Text Content
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  child: Text(data.title, style: AppTextStyles.h1),
                ),
                const SizedBox(height: 16),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    data.description,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  OnboardingData({required this.title, required this.description, required this.image});
}
