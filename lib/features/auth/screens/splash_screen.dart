import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulse;
  late Animation<double> _bgRotate;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _logoCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _bgRotate =
        Tween<double>(begin: 0, end: 2 * math.pi).animate(_bgCtrl);

    _logoCtrl.forward().then((_) => _textCtrl.forward());
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      context.read<AuthProvider>().initialize(),
      Future.delayed(const Duration(milliseconds: 2400)),
    ]);
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(
        context,
        FlavorConfig.isCollector ? '/collector' : '/household',
      );
    } else {
      final showOnboarding = await shouldShowOnboarding();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        showOnboarding ? '/onboarding' : '/login',
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Stack(
        children: [
          // ── Animated background geometry ─────────────────────────────
          AnimatedBuilder(
            animation: _bgRotate,
            builder: (_, __) => CustomPaint(
              painter: _SplashBgPainter(angle: _bgRotate.value),
              size: size,
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glow ring behind logo
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.steelBlue.withAlpha(18),
                    ),
                  ),
                ),

                // Logo mark — positioned on top of glow ring
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Transform.translate(
                      offset: const Offset(0, -78),
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.steelBlue.withAlpha(130),
                              blurRadius: 48,
                              spreadRadius: 4,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BL',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Wordmark + tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Transform.translate(
                      offset: const Offset(0, -36),
                      child: Column(
                        children: [
                          Text(
                            FlavorConfig.appName,
                            style: AppTextStyles.h1.copyWith(fontSize: 34),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.steelBlue.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.steelBlue.withAlpha(60)),
                            ),
                            child: Text(
                              FlavorConfig.tagline,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.skyBlue,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom loading bar ────────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: const _ProgressBar(),
            ),
          ),

          // ── Version tag ───────────────────────────────────────────────
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Text(
                'v2.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.muted, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated background geometry ─────────────────────────────────────────────

class _SplashBgPainter extends CustomPainter {
  const _SplashBgPainter({required this.angle});
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Rotating large circles in corners
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;

    for (var i = 0; i < 3; i++) {
      final t = angle + i * (2 * math.pi / 3);
      final x = cx + math.cos(t) * size.width * 0.45;
      final y = cy + math.sin(t) * size.height * 0.38;
      paint.color = AppColors.steelBlue.withAlpha(12 + i * 5);
      canvas.drawCircle(Offset(x, y), 90 + i * 30, paint);
    }

    // Subtle grid dots
    const step = 40.0;
    final dotPaint = Paint()
      ..color = AppColors.steelBlue.withAlpha(14)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Diagonal accent lines
    final linePaint = Paint()
      ..color = AppColors.steelBlue.withAlpha(18)
      ..strokeWidth = 1;
    for (var i = -5; i < 12; i++) {
      final start = Offset(i * 80.0, 0);
      final end = Offset(i * 80.0 + size.height * 0.4, size.height);
      canvas.drawLine(start, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter old) => old.angle != angle;
}

// ── Animated progress bar ─────────────────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  const _ProgressBar();

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward();
    _progress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: AnimatedBuilder(
            animation: _progress,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress.value,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.steelBlue),
                minHeight: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
