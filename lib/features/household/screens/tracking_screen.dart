import 'dart:async';
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

  void _onMapCreated(GoogleMapController ctrl) {
    if (!_mapCtrl.isCompleted) _mapCtrl.complete(ctrl);
    ctrl.setMapStyle(kDarkMapStyle);
    // Animate to pickup location once map is ready
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

    return Scaffold(
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
                  : GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _pickupLatLng,
                        zoom: 15,
                      ),
                      markers: markers,
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
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
