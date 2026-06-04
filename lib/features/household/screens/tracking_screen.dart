import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routing/routing_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/l10n/strings.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/chat_sheet.dart';

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _bearingDeg(LatLng from, LatLng to) {
  final dLng = (to.longitude - from.longitude) * pi / 180;
  final lat1 = from.latitude  * pi / 180;
  final lat2 = to.latitude    * pi / 180;
  final y = sin(dLng) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}

/// Renders a directional arrow icon (vehicle heading indicator) as a PNG.
Future<Uint8List> _buildTruckIcon() async {
  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  // Glow
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 1,
    Paint()
      ..color = const Color(0x405483B3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  // Fill
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 5,
    Paint()..color = const Color(0xFF5483B3),
  );
  // Stroke
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 5,
    Paint()
      ..color = const Color(0xFFC1E8FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke,
  );
  // Arrow pointing up (maplibre rotates it to face travel direction)
  final path = Path()
    ..moveTo(size / 2, 10)
    ..lineTo(size / 2 - 9, size - 14)
    ..lineTo(size / 2, size - 20)
    ..lineTo(size / 2 + 9, size - 14)
    ..close();
  canvas.drawPath(path, Paint()..color = Colors.white);

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {

  // MapLibre
  MapLibreMapController? _mapCtrl;
  bool _styleLoaded = false;
  Circle? _pickupCircle;
  Symbol? _truckSymbol;
  Line?   _routeLine;

  // Booking data
  Map<String, dynamic>? _booking;
  bool _loading = true;

  // Collector position tracking
  double? _prevCollectorLat;
  double? _prevCollectorLng;

  // Route state
  double? _routeFetchLat;
  double? _routeFetchLng;

  // Smooth animation (Bolt-style)
  LatLng? _collectorAnimPos;
  LatLng? _collectorPrevPos;
  LatLng? _collectorTargetPos;
  double  _collectorBearing = 0;
  late AnimationController _markerAnim;

  @override
  void initState() {
    super.initState();
    _markerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_tickMarker);
    _loadAndListen();
  }

  @override
  void dispose() {
    _markerAnim.dispose();
    _mapCtrl?.onCircleTapped.remove(_dummy);
    if (mounted) {
      try { context.read<HouseholdProvider>().stopListening(); } catch (_) {}
    }
    super.dispose();
  }

  void _dummy(Circle _) {}

  // ── Map lifecycle ──────────────────────────────────────────────────────────

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    // Register truck icon
    final iconBytes = await _buildTruckIcon();
    await _mapCtrl?.addImage('binlink-truck', iconBytes);

    // Pickup circle
    _pickupCircle = await _mapCtrl?.addCircle(CircleOptions(
      geometry:          _pickupLatLng,
      circleRadius:      11,
      circleColor:       '#052659',
      circleStrokeColor: '#C1E8FF',
      circleStrokeWidth: 3.0,
      circleOpacity:     0.95,
    ));

    // Initial camera
    await _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickupLatLng, 15.0),
    );

    // If collector already has a position, place the truck immediately
    if (_collectorAnimPos != null && _truckSymbol == null) {
      await _placeTruckSymbol(_collectorAnimPos!);
    }
  }

  Future<void> _placeTruckSymbol(LatLng pos) async {
    if (_mapCtrl == null) return;
    _truckSymbol = await _mapCtrl!.addSymbol(SymbolOptions(
      geometry:   pos,
      iconImage:  'binlink-truck',
      iconSize:   1.0,
      iconRotate: _collectorBearing,
    ));
  }

  // ── Animation tick — NO setState, pure imperative ──────────────────────────

  void _tickMarker() {
    if (_collectorPrevPos == null || _collectorTargetPos == null) return;
    final t = CurvedAnimation(parent: _markerAnim, curve: Curves.easeOut).value;
    _collectorAnimPos = LatLng(
      _collectorPrevPos!.latitude  +
          (_collectorTargetPos!.latitude  - _collectorPrevPos!.latitude)  * t,
      _collectorPrevPos!.longitude +
          (_collectorTargetPos!.longitude - _collectorPrevPos!.longitude) * t,
    );
    if (_truckSymbol != null && _mapCtrl != null) {
      _mapCtrl!.updateSymbol(_truckSymbol!, SymbolOptions(
        geometry:   _collectorAnimPos!,
        iconRotate: _collectorBearing,
      ));
    }
  }

  void _animateCollectorTo(double lat, double lng) async {
    final newPos = LatLng(lat, lng);
    if (_collectorAnimPos != null) {
      _collectorBearing = _bearingDeg(_collectorAnimPos!, newPos);
    }
    _collectorPrevPos   = _collectorAnimPos ?? newPos;
    _collectorTargetPos = newPos;
    _markerAnim.forward(from: 0);
    _mapCtrl?.animateCamera(CameraUpdate.newLatLng(newPos));

    // Place truck symbol on first position
    if (_truckSymbol == null && _styleLoaded) {
      _collectorAnimPos = newPos;
      await _placeTruckSymbol(newPos);
    }
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  LatLng get _pickupLatLng => LatLng(
    (_booking?['pickupLat'] as num?)?.toDouble() ?? 5.6037,
    (_booking?['pickupLng'] as num?)?.toDouble() ?? -0.1870,
  );

  Future<void> _loadAndListen() async {
    try {
      final res = await ApiClient.get('/api/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = Map<String, dynamic>.from(res.data['data'] as Map);
          _loading = false;
        });
        // Move camera to pickup once we know it, if style loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _styleLoaded) {
            _mapCtrl?.animateCamera(
                CameraUpdate.newLatLngZoom(_pickupLatLng, 15.0));
            _mapCtrl?.updateCircle(
                _pickupCircle!, CircleOptions(geometry: _pickupLatLng));
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    context.read<HouseholdProvider>().listenToBooking(widget.bookingId);
  }

  Future<void> _fetchRoute(double oLat, double oLng) async {
    final result = await RoutingService.getRoute(
      LatLng(oLat, oLng),
      _pickupLatLng,
    );
    if (!mounted || _mapCtrl == null) return;
    final points = result.points.isNotEmpty ? result.points : null;

    // Update or create route line
    if (points != null && points.length > 1) {
      if (_routeLine != null) {
        await _mapCtrl!.updateLine(_routeLine!, LineOptions(geometry: points));
      } else {
        _routeLine = await _mapCtrl!.addLine(LineOptions(
          geometry:    points,
          lineColor:   '#5483B3',
          lineWidth:   4.0,
          lineOpacity: 0.85,
        ));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prov         = context.watch<HouseholdProvider>();
    final status       = _booking?['status'] as String? ?? 'PENDING';
    final collectorLat = prov.collectorLat;
    final collectorLng = prov.collectorLng;

    // Trigger animation when collector moves
    if (collectorLat != null && collectorLng != null &&
        (collectorLat != _prevCollectorLat || collectorLng != _prevCollectorLng)) {
      _prevCollectorLat = collectorLat;
      _prevCollectorLng = collectorLng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateCollectorTo(collectorLat, collectorLng);
      });
    }

    // Refresh route when collector moves > 200 m from last fetch
    if (collectorLat != null && collectorLng != null && _booking != null) {
      final fetchLat = _routeFetchLat;
      final fetchLng = _routeFetchLng;
      if (fetchLat == null || fetchLng == null ||
          _haversineKm(collectorLat, collectorLng, fetchLat, fetchLng) > 0.2) {
        _routeFetchLat = collectorLat;
        _routeFetchLng = collectorLng;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fetchRoute(collectorLat, collectorLng);
        });
      }
    }

    // ETA
    String? etaLabel;
    if (collectorLat != null && collectorLng != null &&
        status != 'COMPLETED' && status != 'ARRIVED') {
      final distKm = _haversineKm(
          collectorLat, collectorLng,
          _pickupLatLng.latitude, _pickupLatLng.longitude);
      final minEta = (distKm / 30 * 60).ceil();
      etaLabel = distKm < 0.1 ? '< 1 min away' : '~$minEta min · ${distKm.toStringAsFixed(1)} km';
    }

    return Scaffold(
      floatingActionButton: _booking != null
          ? FloatingActionButton(
              onPressed: () => showChatSheet(context,
                  bookingId: widget.bookingId, myRole: 'HOUSEHOLD'),
              backgroundColor: AppColors.steelBlue,
              child: const Icon(PhosphorIconsFill.chatCircle,
                  color: AppColors.white, size: 24),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.white),
                    ),
                    Expanded(child: Text(S.of(context).liveTracking,
                        style: AppTextStyles.h3)),
                    if (_booking != null)
                      StatusBadge(status: status, animate: true),
                  ],
                ),
              ),
            ),

            // Map
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.steelBlue))
                  : Stack(
                      children: [
                        // MapLibre map
                        Positioned.fill(
                          child: MapLibreMap(
                            styleString: kMapStyleUrl,
                            initialCameraPosition: CameraPosition(
                              target: _pickupLatLng,
                              zoom:   15.0,
                            ),
                            onMapCreated: (ctrl) => _mapCtrl = ctrl,
                            onStyleLoadedCallback: _onStyleLoaded,
                            myLocationEnabled: false,
                            compassEnabled:    false,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled:   false,
                          ),
                        ),

                        // ETA overlay chip
                        if (etaLabel != null)
                          Positioned(
                            top: 12, left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.deepOcean.withAlpha(230),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.steelBlue.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIconsFill.clock,
                                      color: AppColors.warning, size: 14),
                                  const SizedBox(width: 6),
                                  Text(etaLabel,
                                      style: AppTextStyles.monoSm.copyWith(
                                          color: AppColors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Bottom info card
            if (_booking != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                decoration: const BoxDecoration(
                  color: AppColors.deepOcean,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _StatusMessage(status: status),
                    const SizedBox(height: 16),
                    if (_booking!['collector'] != null) ...[
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                Fmt.initials(_booking!['collector']
                                    ['fullName'] as String?),
                                style: AppTextStyles.h4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _booking!['collector']['fullName']
                                          as String? ?? 'Collector',
                                  style: AppTextStyles.h4,
                                ),
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsFill.star,
                                        color: AppColors.warning, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_booking!['collector']['rating'] ?? 5.0}',
                                      style: AppTextStyles.monoSm,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (status == 'COMPLETED')
                            const Icon(PhosphorIconsFill.checkCircle,
                                color: AppColors.success, size: 28)
                          else ...[
                            if (_booking!['collector']['phone'] != null)
                              _ActionCircle(
                                icon: PhosphorIconsFill.phone,
                                color: AppColors.success,
                                onTap: () => launchUrl(Uri.parse(
                                  'tel:${_booking!['collector']['phone']}')),
                              ),
                            const SizedBox(width: 8),
                            _ActionCircle(
                              icon: PhosphorIconsFill.navigationArrow,
                              color: AppColors.steelBlue,
                              onTap: () {
                                final lat = (_booking!['pickupLat'] as num?)?.toDouble();
                                final lng = (_booking!['pickupLng'] as num?)?.toDouble();
                                if (lat == null || lng == null) return;
                                launchUrl(Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1'
                                  '&destination=$lat,$lng&travelmode=driving',
                                ), mode: LaunchMode.externalApplication);
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin,
                            color: AppColors.skyBlue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _booking!['pickupAddress'] as String? ?? '',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
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

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, msg, color) = switch (status) {
      'PENDING'   => (PhosphorIconsRegular.clock,    'Waiting for a collector to accept...', AppColors.warning),
      'ACCEPTED'  => (PhosphorIconsFill.checkCircle, 'Collector accepted your request!',     AppColors.steelBlue),
      'EN_ROUTE'  => (PhosphorIconsFill.truck,       'Collector is on the way to you!',      AppColors.warning),
      'ARRIVED'   => (PhosphorIconsFill.mapPin,      'Collector has arrived!',               AppColors.success),
      'COMPLETED' => (PhosphorIconsFill.sparkle,     'Pickup complete — great job!',         AppColors.success),
      _           => (PhosphorIconsRegular.question, status,                                 AppColors.muted),
    };
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: AppTextStyles.h4)),
      ],
    );
  }
}
