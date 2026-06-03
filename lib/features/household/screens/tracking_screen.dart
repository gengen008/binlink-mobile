import 'dart:async';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/chat_sheet.dart';

// Haversine distance in km between two lat/lng points
double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final Completer<GoogleMapController> _mapCtrl = Completer();
  Map<String, dynamic>? _booking;
  bool _loading = true;

  // Track previous collector position to avoid redundant camera moves
  double? _prevCollectorLat;
  double? _prevCollectorLng;

  // Route: real road polyline from Directions API
  List<LatLng>? _routePoints;
  double? _routeFetchLat;
  double? _routeFetchLng;

  void _onMapCreated(GoogleMapController ctrl) {
    if (!_mapCtrl.isCompleted) _mapCtrl.complete(ctrl);
    if (_booking != null) {
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(_pickupLatLng, 15));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAndListen();
  }

  Future<void> _loadAndListen() async {
    try {
      final res = await ApiClient.get('/api/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = Map<String, dynamic>.from(res.data['data'] as Map);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;
    context.read<HouseholdProvider>().listenToBooking(widget.bookingId);
  }

  @override
  void dispose() {
    context.read<HouseholdProvider>().stopListening();
    super.dispose();
  }

  LatLng get _pickupLatLng => LatLng(
    (_booking?['pickupLat'] as num?)?.toDouble() ?? 5.6037,
    (_booking?['pickupLng'] as num?)?.toDouble() ?? -0.1870,
  );

  Future<void> _fetchRoute(double oLat, double oLng) async {
    try {
      final res = await ApiClient.get('/api/directions', params: {
        'olat': oLat.toString(),
        'olng': oLng.toString(),
        'dlat': _pickupLatLng.latitude.toString(),
        'dlng': _pickupLatLng.longitude.toString(),
      });
      final encoded = res.data['data']?['points'] as String?;
      if (encoded != null && mounted) {
        setState(() => _routePoints = _decodePolyline(encoded));
      }
    } catch (_) {}
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final status = _booking?['status'] as String? ?? 'PENDING';
    final collectorLat = prov.collectorLat;
    final collectorLng = prov.collectorLng;

    // Animate camera to collector when their position updates
    if (collectorLat != null && collectorLng != null &&
        (collectorLat != _prevCollectorLat || collectorLng != _prevCollectorLng)) {
      _prevCollectorLat = collectorLat;
      _prevCollectorLng = collectorLng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapCtrl.future.then((ctrl) {
          ctrl.animateCamera(CameraUpdate.newLatLng(LatLng(collectorLat, collectorLng)));
        });
      });
    }

    // Fetch/refresh real road route when collector moves >200m from last fetch
    if (collectorLat != null && collectorLng != null && _booking != null) {
      final fetchLat = _routeFetchLat;
      final fetchLng = _routeFetchLng;
      if (fetchLat == null || fetchLng == null ||
          _haversineKm(collectorLat, collectorLng, fetchLat, fetchLng) > 0.2) {
        _routeFetchLat = collectorLat;
        _routeFetchLng = collectorLng;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchRoute(collectorLat, collectorLng);
        });
      }
    }

    // Build markers
    final markers = <Marker>{
      if (_booking != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      if (collectorLat != null && collectorLng != null)
        Marker(
          markerId: const MarkerId('collector'),
          position: LatLng(collectorLat, collectorLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Collector'),
        ),
    };

    // Route polyline: real road route when available, straight dashed fallback
    final hasRealRoute = _routePoints != null && _routePoints!.length > 1;
    final polylines = <Polyline>{
      if (collectorLat != null && collectorLng != null)
        Polyline(
          polylineId: const PolylineId('route'),
          points: hasRealRoute
              ? _routePoints!
              : [LatLng(collectorLat, collectorLng), _pickupLatLng],
          color: AppColors.steelBlue.withAlpha(hasRealRoute ? 220 : 160),
          width: hasRealRoute ? 4 : 3,
          patterns: hasRealRoute ? [] : [PatternItem.dash(12), PatternItem.gap(8)],
        ),
    };

    // ETA: distance / 30 km/h
    String? etaLabel;
    if (collectorLat != null && collectorLng != null &&
        status != 'COMPLETED' && status != 'ARRIVED') {
      final distKm = _haversineKm(
          collectorLat, collectorLng,
          _pickupLatLng.latitude, _pickupLatLng.longitude);
      final minEta = (distKm / 30 * 60).ceil();
      etaLabel = distKm < 0.1
          ? '< 1 min away'
          : '~$minEta min · ${distKm.toStringAsFixed(1)} km';
    }

    return Scaffold(
      floatingActionButton: _booking != null
          ? FloatingActionButton(
              onPressed: () => showChatSheet(
                context,
                bookingId: widget.bookingId,
                myRole: 'HOUSEHOLD',
              ),
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
                      icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                    ),
                    const Expanded(child: Text('Live Tracking', style: AppTextStyles.h3)),
                    if (_booking != null) StatusBadge(status: status, animate: true),
                  ],
                ),
              ),
            ),

            // Google Map
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.steelBlue))
                  : Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _pickupLatLng,
                            zoom: 15,
                          ),
                          style: kDarkMapStyle,
                          markers: markers,
                          polylines: polylines,
                          mapType: MapType.normal,
                          zoomControlsEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                        // ETA chip overlay
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
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                Fmt.initials(_booking!['collector']['fullName'] as String?),
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
                                  _booking!['collector']['fullName'] as String? ?? 'Collector',
                                  style: AppTextStyles.h4,
                                ),
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsFill.star, color: AppColors.warning, size: 14),
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
                            const Icon(PhosphorIconsFill.checkCircle, color: AppColors.success, size: 28),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin, color: AppColors.skyBlue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _booking!['pickupAddress'] as String? ?? '',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, msg, color) = switch (status) {
      'PENDING'   => (PhosphorIconsRegular.clock,       'Waiting for a collector to accept...', AppColors.warning),
      'ACCEPTED'  => (PhosphorIconsFill.checkCircle,    'Collector accepted your request!',      AppColors.steelBlue),
      'EN_ROUTE'  => (PhosphorIconsFill.truck,          'Collector is on the way to you!',       AppColors.warning),
      'ARRIVED'   => (PhosphorIconsFill.mapPin,         'Collector has arrived!',                AppColors.success),
      'COMPLETED' => (PhosphorIconsFill.sparkle,        'Pickup complete — great job!',          AppColors.success),
      _           => (PhosphorIconsRegular.question,    status,                                  AppColors.muted),
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
