import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../providers/collector_provider.dart';
import '../../../shared/widgets/binlink_map.dart';

class CollectorMapTab extends StatefulWidget {
  const CollectorMapTab({super.key, required this.pos});
  final ll.LatLng? pos;

  @override
  State<CollectorMapTab> createState() => _CollectorMapTabState();
}

class _CollectorMapTabState extends State<CollectorMapTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.pos == null) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final prov = context.watch<CollectorProvider>();
    final requests = prov.pendingRequests;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // ── Map ──
          Positioned.fill(
            child: BinLinkMap(
              initialPosition: widget.pos!,
              myLocationEnabled: prov.isOnline,
            ),
          ),

          // ── Top Earnings Bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: FadeInDown(
              child: _EarningsPill(earnings: prov.todayEarnings, pickups: prov.todayPickups),
            ),
          ),

          // ── Online/Offline Toggle (The BIG Button) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: _OnlineToggleBtn(
                isOnline: prov.isOnline,
                onTap: () => prov.toggleOnline(),
              ),
            ),
          ),

          // ── Request Overlay ──
          if (prov.isOnline && requests.isNotEmpty)
            _IncomingRequestOverlay(
              request: requests.first,
              collectorPos: widget.pos!,
              onAccept: () => prov.acceptRequest(requests.first['id']),
              onDecline: () => prov.declineRequest(requests.first['id']),
            ),
        ],
      ),
    );
  }
}

class _EarningsPill extends StatelessWidget {
  const _EarningsPill({required this.earnings, required this.pickups});
  final double earnings;
  final int pickups;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(PhosphorIconsFill.coins, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            Fmt.currency(earnings),
            style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: Colors.white24),
          const SizedBox(width: 12),
          Text(
            "$pickups jobs",
            style: AppTextStyles.label.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _OnlineToggleBtn extends StatelessWidget {
  const _OnlineToggleBtn({required this.isOnline, required this.onTap});
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.danger : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84, height: 84,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withAlpha(120), blurRadius: 25, spreadRadius: 5),
            const BoxShadow(color: Colors.white24, blurRadius: 0, spreadRadius: 4),
          ],
        ),
        child: Center(
          child: Text(
            isOnline ? "STOP" : "GO",
            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22, letterSpacing: 1.0),
          ),
        ),
      ),
    );
  }
}

class _IncomingRequestOverlay extends StatefulWidget {
  const _IncomingRequestOverlay({
    required this.request, 
    required this.collectorPos,
    required this.onAccept,
    required this.onDecline,
  });
  final Map<String, dynamic> request;
  final ll.LatLng collectorPos;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_IncomingRequestOverlay> createState() => _IncomingRequestOverlayState();
}

class _IncomingRequestOverlayState extends State<_IncomingRequestOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  int _seconds = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 0) {
        timer.cancel();
        widget.onDecline();
      } else {
        if (mounted) setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distMeters = LocationService.distanceMeters(
      widget.collectorPos.latitude, widget.collectorPos.longitude,
      (widget.request['pickupLat'] as num).toDouble(), 
      (widget.request['pickupLng'] as num).toDouble(),
    );
    final payout = Fmt.toDouble(widget.request['totalAmount']) * 0.9;

    return ZoomIn(
      duration: const Duration(milliseconds: 400),
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.premiumBlack,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white10),
              boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(30), blurRadius: 50)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text("NEW PICKUP", style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
                Image.asset(AppAssets.truck3d, width: 80, height: 80),
                const SizedBox(height: 24),
                Text(Fmt.currency(payout), style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 44)),
                const SizedBox(height: 8),
                Text("Your Earnings", style: AppTextStyles.label.copyWith(color: Colors.white54)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsFill.mapPin, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(LocationService.formatDistance(distMeters), style: AppTextStyles.h3.copyWith(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 40),
                
                // ── Accept Circle ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140, height: 140,
                      child: CircularProgressIndicator(
                        value: 1 - _anim.value,
                        strokeWidth: 10,
                        color: AppColors.primary,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onAccept,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 20)],
                        ),
                        child: Center(
                          child: Text("ACCEPT", style: AppTextStyles.h3.copyWith(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: widget.onDecline,
                  child: Text("DECLINE", style: AppTextStyles.label.copyWith(color: Colors.white38, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
