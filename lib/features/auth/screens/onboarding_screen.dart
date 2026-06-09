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
      bgColor: AppColors.primary800,
    ),
    OnboardingData(
      title: "Schedule\nPickups Instantly",
      description: "Choose your waste type, select a bin size, and get matched with a collector in seconds.",
      image: AppAssets.onboarding2,
      bgColor: AppColors.primary700,
    ),
    OnboardingData(
      title: "Track Your\nImpact Live",
      description: "Follow your collector on the map and see how much waste you've diverted from landfills.",
      image: AppAssets.onboarding3,
      bgColor: AppColors.primary600,
    ),
    OnboardingData(
      title: "Connect with\nVerified Experts",
      description: "Our collectors are trained, verified, and ready to handle your waste professionally.",
      image: AppAssets.onboarding4,
      bgColor: AppColors.primary900,
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: _pages[_currentPage].bgColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _pages[_currentPage].bgColor,
              AppColors.primary900,
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Background Pattern ──
            Positioned(
              top: -50, right: -50,
              child: FadeInRight(
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200, left: -30,
              child: FadeInLeft(
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(100),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 300, right: 20,
              child: FadeInUp(
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // ── Background & Content ──
            PageView.builder(
              controller: _pageController,
              onPageChanged: (v) => setState(() => _currentPage = v),
              itemCount: _pages.length,
              itemBuilder: (context, i) {
                return _OnboardingPage(data: _pages[i], isActive: i == _currentPage);
              },
            ),

            // ── Bottom Controls ──
            Positioned(
              bottom: 60,
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
                          width: _currentPage == i ? 32 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 48),

                    // Button
                    AppButton(
                      label: _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _onFinish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuart,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _onFinish,
                        child: Text(
                          "Skip",
                          style: AppTextStyles.button.copyWith(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      const SizedBox(height: 48),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.isActive});
  final OnboardingData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 80),
        // Illustration
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: AnimatedScale(
              scale: isActive ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SvgPicture.asset(
                  data.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        // Text Content
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedSlide(
                  offset: isActive ? Offset.zero : const Offset(0, 0.2),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      data.title, 
                      style: AppTextStyles.display.copyWith(fontSize: 32, height: 1.1, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSlide(
                  offset: isActive ? Offset.zero : const Offset(0, 0.2),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      data.description,
                      style: AppTextStyles.body.copyWith(color: Colors.white.withAlpha(180)),
                      textAlign: TextAlign.center,
                    ),
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
  final Color bgColor;
  OnboardingData({required this.title, required this.description, required this.image, required this.bgColor});
}
