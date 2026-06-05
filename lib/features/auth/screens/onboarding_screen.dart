import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
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

// ── Onboarding page data (BinLink content, Rydr visual layout) ───────────────

class _Page {
  final String icon;   // svg asset path
  final String text;
  final String desc;
  const _Page({required this.icon, required this.text, required this.desc});
}

final List<_Page> _screens = [
  const _Page(
    icon: RydrAssets.home,
    text: 'Clean Cities Start Here',
    desc: 'BinLink connects households with trusted\ncollectors for a cleaner Ghana.',
  ),
  const _Page(
    icon: RydrAssets.stopwatch,
    text: 'Pick Up On Your Schedule',
    desc: 'Book same-day pickups or schedule ahead.\nWe work around your timing.',
  ),
  const _Page(
    icon: RydrAssets.locate,
    text: 'Watch Your Collector Live',
    desc: 'Real-time GPS tracking. Know exactly\nwhen your collector will arrive.',
  ),
];

// ── Main screen (exact Rydr Onboarding widget tree) ───────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _storeOnboardInfo() async {
    await markOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;

    // Rydr exact: Scaffold(white) > Padding(top:20) > Column([
    //   YMargin(80), Container(sw,45, logo image), SizedBox(30),
    //   Expanded(Stack([cityBg, PageView, dots(bottom:100), buttons(bottom:25)]))
    // ])
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Rydr: Container(sw, 45, DecorationImage(logo, contain))
            Container(
              width: sw,
              height: 45,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.contain,
                  image: AssetImage(RydrAssets.logo),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Stack(
                children: [
                  // Rydr: city background image
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(RydrAssets.citybg),
                      ),
                    ),
                  ),

                  // Rydr: PageView
                  PageView.builder(
                    itemCount: _screens.length,
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => setState(() => currentIndex = index),
                    itemBuilder: (_, index) {
                      return Column(
                        children: [
                          const SizedBox(height: 220),
                          Column(
                            children: [
                              // Rydr: Container(320, 160, DecorationImage(screens[i].img))
                              // BinLink: SVG icon in a rounded container
                              Container(
                                width: 320,
                                height: 160,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(220),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(30),
                                  child: SvgPicture.asset(
                                    _screens[index].icon,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF1F2421),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Rydr: Text(text, poppins, w500, 17.3, SecondaryColor)
                              Text(
                                _screens[index].text,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFF3F3C1),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Rydr: Text(desc, poppins, w300, 13.6, white)
                              Text(
                                _screens[index].desc,
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                overflow: TextOverflow.clip,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 13.6,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  // Rydr: dot indicators (bottom: 100)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100.0),
                      child: SizedBox(
                        height: 10.0,
                        child: ListView.builder(
                          itemCount: _screens.length,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                  width: 45,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    color: currentIndex == index
                                        ? const Color(0xFF1F2421)
                                        : const Color(0xFFEBEBEB),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Rydr: bottom buttons (bottom: 25) — Skip + circular next
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Skip button (hidden on last page)
                          currentIndex != _screens.length - 1
                              ? InkWell(
                                  onTap: () async {
                                    final nav = Navigator.of(context);
                                    await _storeOnboardInfo();
                                    if (!mounted) return;
                                    nav.pushReplacementNamed('/login');
                                  },
                                  child: Container(
                                    height: 52,
                                    width: 93,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14.0),
                                      color: const Color(0xFF1F2421),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Skip',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 52, width: 93),

                          const SizedBox(width: 50),

                          // Circular next / finish button
                          InkWell(
                            onTap: () async {
                              if (currentIndex == _screens.length - 1) {
                                final nav = Navigator.of(context);
                                await _storeOnboardInfo();
                                if (!mounted) return;
                                nav.pushReplacementNamed('/login');
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Container(
                              height: 61,
                              width: 61,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF1F2421),
                              ),
                              child: Center(
                                child: SvgPicture.asset(RydrAssets.rightarrow),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
