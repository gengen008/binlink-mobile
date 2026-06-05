import 'dart:async';

import 'package:flutter/material.dart';

/// Bolt/Uber-style sonar animation used when a booking is in PENDING/SEARCHING state.
///
/// Three concentric rings expand outward with staggered 667 ms delays, each
/// fading from [ringColor] to transparent over [duration].
class SearchingRadarWidget extends StatefulWidget {
  const SearchingRadarWidget({
    super.key,
    this.radius       = 70.0,
    this.ringColor    = const Color(0xFF5483B3),
    this.strokeWidth  = 2.0,
    this.duration     = const Duration(milliseconds: 2000),
  });

  final double radius;
  final Color  ringColor;
  final double strokeWidth;
  final Duration duration;

  @override
  State<SearchingRadarWidget> createState() => _SearchingRadarWidgetState();
}

class _SearchingRadarWidgetState extends State<SearchingRadarWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>>   _anims;
  final List<Timer> _startTimers = [];

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (_) => AnimationController(vsync: this, duration: widget.duration),
    );

    _anims = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();

    // Stagger: ring 0 starts immediately, ring 1 after 667 ms, ring 2 after 1333 ms
    _controllers[0].repeat();
    for (var i = 1; i < 3; i++) {
      _startTimers.add(Timer(Duration(milliseconds: i * 667), () {
        if (mounted) _controllers[i].repeat();
      }));
    }
  }

  @override
  void dispose() {
    for (final t in _startTimers) { t.cancel(); }
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (_, __) => CustomPaint(
        size: Size(widget.radius * 2, widget.radius * 2),
        painter: _RadarPainter(
          values:      _anims.map((a) => a.value).toList(),
          radius:      widget.radius,
          color:       widget.ringColor,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> values;
  final double       radius;
  final Color        color;
  final double       strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final t in values) {
      final opacity = (1.0 - t) * 0.6;
      if (opacity < 0.01) continue;
      canvas.drawCircle(
        center,
        t * radius,
        Paint()
          ..color      = color.withValues(alpha: opacity)
          ..style      = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values || old.radius != radius;
}
