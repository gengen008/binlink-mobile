import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../../core/design_system/collector_design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/components/binlink_map.dart';
import '../../../shared/components/searching_radar_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/collector_provider.dart';

class CollectorMapTab extends StatelessWidget {
  const CollectorMapTab({super.key, required this.pos});
  final ll.LatLng? pos;

  @override
  Widget build(BuildContext context) {
    final p = pos;
    final provider = context.watch<CollectorProvider>();
    final user = context.watch<AuthProvider>().user;
    if (p == null) {
      return const Center(child: SearchingRadarWidget(color: CollectorColors.warning));
    }
    final capacity = ((user?.currentLoadKg ?? 0) / (user?.maxCapacityKg ?? 500) * 100).clamp(0, 100).round();
    final etaText = _etaText(provider.currentActivePickup);
    return Stack(
      children: [
        Positioned.fill(child: BinLinkMap(initialPosition: p, myLocationEnabled: provider.isOnline)),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 14,
          left: 16,
          right: 16,
          child: CPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              const CIcon('map', color: CollectorColors.green),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Fmt.currency(provider.todayEarnings), style: CollectorType.title),
                Text(provider.isOnline ? 'Online and receiving jobs' : 'Offline. Tap GO to start', style: CollectorType.caption.copyWith(color: provider.isOnline ? CollectorColors.green : const Color(0xFFB6C0CC))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: CollectorColors.dark, borderRadius: BorderRadius.circular(20)),
                child: Text('$capacity%', style: CollectorType.caption.copyWith(color: CollectorColors.green, fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 104,
          left: 22,
          child: _Metric(label: 'ETA', value: etaText),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 104,
          right: 22,
          child: _Metric(label: 'Speed', value: '${provider.currentSpeedKph.round()} km/h'),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 104),
            child: GestureDetector(
              onTap: provider.toggleOnline,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isOnline ? CollectorColors.red : CollectorColors.green,
                  border: Border.all(color: CollectorColors.white, width: 5),
                  boxShadow: [BoxShadow(color: (provider.isOnline ? CollectorColors.red : CollectorColors.green).withAlpha(90), blurRadius: 34, spreadRadius: 8)],
                ),
                child: Center(child: Text(provider.isOnline ? 'STOP' : 'GO', style: CollectorType.title.copyWith(color: provider.isOnline ? Colors.white : CollectorColors.dark))),
              ),
            ),
          ),
        ),
        if (provider.isOnline && provider.pendingRequests.isNotEmpty) _IncomingRequest(request: provider.pendingRequests.first),
      ],
    );
  }

  String _etaText(Map<String, dynamic>? booking) {
    final raw = booking?['etaMinutes'] ?? booking?['eta'] ?? booking?['estimatedMinutes'];
    final minutes = raw is num ? raw.round() : int.tryParse(raw?.toString() ?? '');
    if (minutes == null || minutes <= 0) return '--';
    return '$minutes min';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => CPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: CollectorType.caption),
          Text(value, style: CollectorType.section),
        ]),
      );
}

class _IncomingRequest extends StatefulWidget {
  const _IncomingRequest({required this.request});
  final Map<String, dynamic> request;

  @override
  State<_IncomingRequest> createState() => _IncomingRequestState();
}

class _IncomingRequestState extends State<_IncomingRequest> with SingleTickerProviderStateMixin {
  static const _seconds = 30;
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(seconds: _seconds))..forward();
  late Timer _timer;
  int _remaining = _seconds;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _handled) return;
      if (_remaining <= 1) {
        _handled = true;
        _timer.cancel();
        context.read<CollectorProvider>().declineRequest(widget.request['id'] as String);
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  @override
  void didUpdateWidget(covariant _IncomingRequest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request['id'] != widget.request['id']) {
      _remaining = _seconds;
      _handled = false;
      _ring.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CollectorProvider>();
    return Container(
      color: Colors.black.withAlpha(218),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const Spacer(),
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) => CustomPaint(
                      size: const Size(210, 210),
                      painter: _CountdownRingPainter(progress: _ring.value, color: CollectorColors.warning),
                    ),
                  ),
                  SvgPicture.asset('assets/collector_assets/workflow/accept_request.svg', height: 150),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Incoming request', style: CollectorType.hero, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.request['pickupAddress'] as String? ?? 'Pickup location nearby', textAlign: TextAlign.center, style: CollectorType.body.copyWith(color: const Color(0xFFC8D0DA))),
            const SizedBox(height: 6),
            Text('Auto reject in $_remaining s', style: CollectorType.caption.copyWith(color: CollectorColors.warning)),
            const Spacer(),
            CButton(label: 'TAP TO ACCEPT', icon: 'jobs', onPressed: () async {
              _handled = true;
              _timer.cancel();
              await provider.acceptRequest(widget.request['id'] as String);
            }),
            const SizedBox(height: 12),
            CButton(label: 'DECLINE', danger: true, secondary: true, onPressed: () async {
              _handled = true;
              _timer.cancel();
              await provider.declineRequest(widget.request['id'] as String);
            }),
          ]),
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white.withAlpha(30);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, 6.28318 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
