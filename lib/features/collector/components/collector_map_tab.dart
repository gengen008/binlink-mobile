import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_map/flutter_map.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../providers/collector_provider.dart';
import '../../../shared/widgets/binlink_map.dart';

class CollectorMapTab extends StatefulWidget {
  const CollectorMapTab({super.key, required this.pos});
  final LatLng pos;

  @override
  State<CollectorMapTab> createState() => _CollectorMapTabState();
}

class _CollectorMapTabState extends State<CollectorMapTab> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final requests = prov.pendingRequests;

    return Stack(
      children: [
        // ── Full Screen Map (Heatmap style) ────────────────────────────────
        Positioned.fill(
          child: BinLinkMap(
            initialPosition: widget.pos,
            myLocationEnabled: prov.isOnline,
          ),
        ),

        // ── Top Stats Bar (Uber Driver style) ──────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.fullBR,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsFill.chartLineUp, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  "Earned ${Fmt.currency(prov.todayEarnings)} today",
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),

        // ── GO / STOP Button (Online Toggle) ──────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: GestureDetector(
              onTap: () => prov.toggleOnline(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: prov.isOnline ? AppColors.danger : AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (prov.isOnline ? AppColors.danger : AppColors.success).withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Text(
                    prov.isOnline ? "OFF" : "GO",
                    style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Incoming Request Overlay ──────────────────────────────────────
        if (prov.isOnline && requests.isNotEmpty)
          _IncomingRequestModal(
            request: requests.first,
            collectorPos: widget.pos,
            onAccept: () => prov.acceptRequest(requests.first['id']),
            onDecline: () => prov.declineRequest(requests.first['id']),
          ),
      ],
    );
  }
}

class _IncomingRequestModal extends StatefulWidget {
  const _IncomingRequestModal({
    required this.request, 
    required this.collectorPos,
    required this.onAccept,
    required this.onDecline,
  });
  final Map<String, dynamic> request;
  final LatLng collectorPos;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_IncomingRequestModal> createState() => _IncomingRequestModalState();
}

class _IncomingRequestModalState extends State<_IncomingRequestModal> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  int _seconds = 15;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 15))..forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 0) {
        timer.cancel();
        widget.onDecline();
      } else {
        if (mounted) setState(() => _seconds--);
      }
    });
    
    // Play radar sound here if we had an audio player
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
    final payout = Fmt.toDouble(widget.request['totalAmount']) * 0.8; // 80% collector cut

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark modal for high contrast
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.success.withAlpha(40), blurRadius: 40, spreadRadius: 10),
            const BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("NEW REQUEST", style: AppTextStyles.meta.copyWith(color: AppColors.success, letterSpacing: 2.0)),
            const SizedBox(height: 16),
            Text(
              "Est. ${Fmt.currency(payout)}",
              style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 36),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsFill.car, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text("${LocationService.formatDistance(distMeters)} away", style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                const SizedBox(width: 16),
                const Icon(PhosphorIconsFill.clock, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text("~${(distMeters / 400).ceil()} min", style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.mapPin, color: Colors.white, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.request['pickupAddress'] ?? "Pickup Location",
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // ── Tap to Accept Ring ──
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) {
                    return SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: 1 - _anim.value,
                        strokeWidth: 8,
                        color: AppColors.success,
                        backgroundColor: Colors.white12,
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: widget.onAccept,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.success.withAlpha(100), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("TAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("TO ACCEPT", style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 10, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            GestureDetector(
              onTap: widget.onDecline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.close, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
