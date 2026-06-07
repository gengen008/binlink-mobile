import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
  int _seconds = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
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

    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.lgBR,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Truck icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(AppAssets.truck, width: 40, height: 40, color: AppColors.success),
              ),
              const SizedBox(height: 12),
              Text("New Request", style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text("${LocationService.formatDistance(distMeters)} away", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) {
                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 1 - _anim.value,
                          strokeWidth: 8,
                          color: AppColors.success,
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: widget.onAccept,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(PhosphorIconsFill.check, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              Text(
                widget.request['pickupAddress'] ?? "Pickup Location",
                textAlign: TextAlign.center,
                style: AppTextStyles.section,
              ),
              const SizedBox(height: 8),
              Text(
                "Estimated Payout: ${Fmt.currency(payout)}",
                style: AppTextStyles.mono.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: widget.onDecline,
                child: Text("Decline", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
