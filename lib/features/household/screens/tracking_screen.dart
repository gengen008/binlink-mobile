import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/binlink_map.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final res = await ApiClient.get('/api/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data['data'];
        });
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final status = _booking?['status'] as String? ?? 'PENDING';
    final pickupPos = LatLng(
      (_booking?['pickupLat'] as num?)?.toDouble() ?? 5.6037,
      (_booking?['pickupLng'] as num?)?.toDouble() ?? -0.1870,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          Positioned.fill(
            child: BinLinkMap(
              initialPosition: pickupPos,
              pickupPosition: pickupPos,
              collectors: prov.collectorLat != null
                  ? [
                      {
                        'id': 'active_collector',
                        'lastLat': prov.collectorLat!,
                        'lastLng': prov.collectorLng!,
                      }
                    ]
                  : const [],
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleNavBtn(icon: PhosphorIconsRegular.arrowLeft, onTap: () => Navigator.pop(context)),
                StatusBadge(status: status, animate: true),
              ],
            ),
          ),

          // ── Bottom Sheet ──────────────────────────────────────────────────
          if (_booking != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.sheetBR,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusMessage(status: status),
                    const SizedBox(height: 24),
                    if (_booking!['collector'] != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surface,
                            child: Text(Fmt.initials(_booking!['collector']['fullName'])),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_booking!['collector']['fullName'] ?? 'Collector', style: AppTextStyles.section),
                                Text(
                                  _booking!['collector']['vehiclePlate'] != null
                                      ? "Vehicle #${_booking!['collector']['vehiclePlate']}"
                                      : "Collector Vehicle",
                                  style: AppTextStyles.meta,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => launchUrl(Uri.parse('tel:${_booking!['collector']['phone'] ?? ''}')),
                            icon: const Icon(PhosphorIconsFill.phone),
                          ),
                          IconButton(
                            onPressed: () => showChatSheet(context, bookingId: widget.bookingId, myRole: 'HOUSEHOLD'),
                            icon: const Icon(PhosphorIconsFill.chatCircle),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_booking!['pickupAddress'] ?? '', style: AppTextStyles.bodyMedium),
                        ),
                      ],
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

class _CircleNavBtn extends StatelessWidget {
  const _CircleNavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (pngAsset, fallbackIcon, msg, color) = switch (status) {
      'PENDING'   => (null, PhosphorIconsFill.clock, 'Finding your collector...', AppColors.warning),
      'ACCEPTED'  => (AppAssets.verifiedBadge, null, 'Collector accepted', AppColors.success),
      'EN_ROUTE'  => (AppAssets.truck, null, 'Collector is on the way', AppColors.info),
      'ARRIVED'   => (AppAssets.gps, null, 'Collector has arrived', AppColors.success),
      'COMPLETED' => (AppAssets.verifiedBadge, null, 'Pickup completed', AppColors.success),
      _           => (null, PhosphorIconsFill.info, status, AppColors.textSecondary),
    };

    Widget iconWidget;
    if (pngAsset != null) {
      iconWidget = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Image.asset(pngAsset, width: 22, height: 22, color: color),
      );
    } else {
      iconWidget = Icon(fallbackIcon!, color: color, size: 24);
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: AppTextStyles.section.copyWith(color: color))),
      ],
    );
  }
}
