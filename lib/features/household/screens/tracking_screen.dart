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
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routing/routing_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/searching_radar_widget.dart';

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

Future<Uint8List> _buildTruckIcon() async {
  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 1,
    Paint()
      ..color = const Color(0x2016A34A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 5,
    Paint()..color = const Color(0xFF16A34A),
  );
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 5,
    Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = ui.PaintingStyle.stroke,
  );
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

  MapLibreMapController? _mapCtrl;
  bool _styleLoaded = false;
  Circle? _pickupCircle;
  Symbol? _truckSymbol;
  Line?   _routeLine;

  Map<String, dynamic>? _booking;
  bool _loading = true;

  double? _prevCollectorLat;
  double? _prevCollectorLng;

  double? _routeFetchLat;
  double? _routeFetchLng;

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
    if (mounted) {
      try { context.read<HouseholdProvider>().stopListening(); } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    final iconBytes = await _buildTruckIcon();
    await _mapCtrl?.addImage('binlink-truck', iconBytes);

    _pickupCircle = await _mapCtrl?.addCircle(CircleOptions(
      geometry:          _pickupLatLng,
      circleRadius:      12,
      circleColor:       '#111827',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 3.0,
      circleOpacity:     1.0,
    ));

    await _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickupLatLng, 15.0),
    );

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

    if (_truckSymbol == null && _styleLoaded) {
      _collectorAnimPos = newPos;
      await _placeTruckSymbol(newPos);
    }
  }

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _styleLoaded) {
            _mapCtrl?.animateCamera(
                CameraUpdate.newLatLngZoom(_pickupLatLng, 15.0));
            if (_pickupCircle != null) {
              _mapCtrl?.updateCircle(
                  _pickupCircle!, CircleOptions(geometry: _pickupLatLng));
            }
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

    if (points != null && points.length > 1) {
      if (_routeLine != null) {
        await _mapCtrl!.updateLine(_routeLine!, LineOptions(geometry: points));
      } else {
        _routeLine = await _mapCtrl!.addLine(LineOptions(
          geometry:    points,
          lineColor:   '#16A34A',
          lineWidth:   4.0,
          lineOpacity: 0.85,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov         = context.watch<HouseholdProvider>();
    final status       = _booking?['status'] as String? ?? 'PENDING';
    final collectorLat = prov.collectorLat;
    final collectorLng = prov.collectorLng;

    if (collectorLat != null && collectorLng != null &&
        (collectorLat != _prevCollectorLat || collectorLng != _prevCollectorLng)) {
      _prevCollectorLat = collectorLat;
      _prevCollectorLng = collectorLng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateCollectorTo(collectorLat, collectorLng);
      });
    }

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
      backgroundColor: Colors.white,
      appBar: AppScaffoldBar(
        title: 'Live Tracking',
        trailing: _booking != null
            ? StatusBadge(status: status, animate: true)
            : null,
      ),
      floatingActionButton: _booking != null
          ? FloatingActionButton(
              onPressed: () => showChatSheet(context,
                  bookingId: widget.bookingId, myRole: 'HOUSEHOLD'),
              backgroundColor: AppColors.primary,
              child: const Icon(PhosphorIconsFill.chatCircle,
                  color: Colors.white, size: 24),
            )
          : null,
      body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : Stack(
                      children: [
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

                        if (status == 'PENDING' || status == 'SEARCHING')
                          Positioned(
                            top: 16, left: 0, right: 0,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SearchingRadarWidget(radius: 55),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: AppRadius.fullBR,
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                                    ),
                                    child: Text(
                                      status == 'SEARCHING'
                                          ? 'Searching for a collector...'
                                          : 'Waiting for acceptance...',
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (etaLabel != null)
                          Positioned(
                            top: 16, left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: AppRadius.fullBR,
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIconsFill.clock,
                                      color: AppColors.primary, size: 16),
                                  const SizedBox(width: 8),
                                  Text(etaLabel,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: Colors.white, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            if (_booking != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.sheetBR,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: AppRadius.fullBR,
                        ),
                      ),
                    ),
                    _StatusMessage(status: status),
                    const SizedBox(height: 24),
                    if (_booking!['collector'] != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              Fmt.initials(_booking!['collector']['fullName'] as String?),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _booking!['collector']['fullName'] as String? ?? 'Collector',
                                  style: AppTextStyles.section,
                                ),
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsFill.star, color: AppColors.warning, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_booking!['collector']['rating'] ?? 5.0}',
                                      style: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (status != 'COMPLETED') ...[
                            _ActionBtn(
                              icon: PhosphorIconsFill.phone,
                              onTap: () => launchUrl(Uri.parse('tel:${_booking!['collector']['phone'] ?? ''}')),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin, color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _booking!['pickupAddress'] as String? ?? '',
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.fullBR,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
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
      'SEARCHING'  => (PhosphorIconsRegular.magnifyingGlass, 'Searching for collector...', AppColors.warning),
      'PENDING'    => (PhosphorIconsRegular.clock,           'Waiting for acceptance...',   AppColors.warning),
      'ASSIGNED'   => (PhosphorIconsFill.userCheck,          'Collector assigned',         AppColors.primary),
      'ACCEPTED'   => (PhosphorIconsFill.checkCircle,        'Collector accepted',         AppColors.primary),
      'ON_THE_WAY' => (PhosphorIconsFill.truck,              'Collector is on the way',    AppColors.warning),
      'EN_ROUTE'   => (PhosphorIconsFill.truck,              'Collector is on the way',    AppColors.warning),
      'ARRIVED'    => (PhosphorIconsFill.mapPin,             'Collector has arrived',      AppColors.success),
      'COLLECTING' => (PhosphorIconsFill.trashSimple,        'Collecting waste...',        AppColors.success),
      'COLLECTED'  => (PhosphorIconsFill.checkCircle,        'Waste collected',            AppColors.success),
      'COMPLETED'  => (PhosphorIconsFill.checkCircle,        'Pickup completed',           AppColors.success),
      'CANCELLED'  => (PhosphorIconsRegular.xCircle,         'Booking cancelled',          AppColors.danger),
      _            => (PhosphorIconsRegular.question,        status,                       AppColors.muted),
    };
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: AppTextStyles.section.copyWith(color: color))),
      ],
    );
  }
}
