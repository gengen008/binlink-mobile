import 'package:flutter/material.dart';

class SearchingRadarWidget extends StatefulWidget {
  const SearchingRadarWidget({super.key, this.color = const Color(0xFF5483B3), this.size = 120});

  final Color color;
  final double size;

  @override
  State<SearchingRadarWidget> createState() => _SearchingRadarWidgetState();
}

class _SearchingRadarWidgetState extends State<SearchingRadarWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _RadarPainter(progress: _controller.value, color: widget.color),
          child: Center(
            child: Container(
              width: widget.size * .24,
              height: widget.size * .24,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color.withAlpha(70), blurRadius: 20)]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1;
      paint.color = color.withAlpha(((1 - p) * 90).round());
      canvas.drawCircle(center, size.shortestSide * .12 + p * size.shortestSide * .38, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
