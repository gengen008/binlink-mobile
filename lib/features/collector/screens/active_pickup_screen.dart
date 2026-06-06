import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/collector_provider.dart';
import '../../../core/routing/routing_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/chat_sheet.dart';

class ActivePickupScreen extends StatefulWidget {
  const ActivePickupScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<ActivePickupScreen> createState() => _ActivePickupScreenState();
}

class _ActivePickupScreenState extends State<ActivePickupScreen> {
  late String _currentStatus;
  final _weightCtrl = TextEditingController();
  MapLibreMapController? _mapCtrl;
  StreamSubscription? _locationSub;
  Circle? _collectorDot;
  Line? _routeLine;
  String? _etaLabel;
  DateTime? _lastRouteFetch;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] as String? ?? 'ACCEPTED';
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _weightCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  LatLng get _pickupPos => LatLng(
        (widget.booking['pickupLat'] as num?)?.toDouble() ?? 5.6037,
        (widget.booking['pickupLng'] as num?)?.toDouble() ?? -0.1870,
      );

  Future<void> _onMapStyleLoaded() async {
    if (_mapCtrl == null) return;
    await _mapCtrl!.addCircle(CircleOptions(
      geometry: _pickupPos,
      circleRadius: 18,
      circleColor: '#16A34A',
      circleStrokeWidth: 3,
      circleStrokeColor: '#FFFFFF',
    ));
    _startLocationStream();
  }

  void _startLocationStream() {
    _locationSub = LocationService.getPositionStream().listen((pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      _updateMap(latLng);
    });
  }

  void _updateMap(LatLng pos) async {
    if (_mapCtrl == null) return;
    if (_collectorDot == null) {
      _collectorDot = await _mapCtrl!.addCircle(CircleOptions(
        geometry: pos,
        circleRadius: 10,
        circleColor: '#111827',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ));
      _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
    } else {
      _mapCtrl!.updateCircle(_collectorDot!, CircleOptions(geometry: pos));
    }
    _maybeRefreshRoute(pos);
  }

  Future<void> _maybeRefreshRoute(LatLng pos) async {
    if (_mapCtrl == null) return;
    final now = DateTime.now();
    if (_lastRouteFetch != null && now.difference(_lastRouteFetch!).inSeconds < 30) return;
    _lastRouteFetch = now;

    final res = await RoutingService.getRoute(pos, _pickupPos);
    if (!mounted || _mapCtrl == null) return;

    if (_routeLine == null) {
      _routeLine = await _mapCtrl!.addLine(LineOptions(
        geometry: res.points,
        lineColor: '#16A34A',
        lineWidth: 4,
        lineOpacity: 0.7,
      ));
    } else {
      _mapCtrl!.updateLine(_routeLine!, LineOptions(geometry: res.points));
    }
    setState(() {
      _etaLabel = res.etaLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final hhName = widget.booking['household']?['fullName'] as String? ?? 'Household';
    final address = widget.booking['pickupAddress'] as String? ?? '';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapLibreMap(
              styleString: kMapStyleUrl,
              initialCameraPosition: CameraPosition(target: _pickupPos, zoom: 14),
              onMapCreated: (c) => _mapCtrl = c,
              onStyleLoadedCallback: _onMapStyleLoaded,
            ),
          ),

          // ── Top Header ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.mdBR,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(PhosphorIconsRegular.arrowLeft)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Active Pickup', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                          Text(address, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    _etaLabel != null 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadius.xsBR),
                          child: Text(_etaLabel!, style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        )
                      : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Sheet (Operational Console) ──
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(Fmt.initials(hhName), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hhName, style: AppTextStyles.section),
                            Text(Fmt.categoryLabel(widget.booking['wasteCategory'] as String? ?? ''), style: AppTextStyles.meta),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => showChatSheet(context, bookingId: widget.booking['id'], myRole: 'COLLECTOR'),
                        icon: const Icon(PhosphorIconsFill.chatCircle, color: AppColors.primary),
                      ),
                      IconButton(
                        onPressed: () => launchUrl(Uri.parse('tel:${widget.booking['household']?['phone'] ?? ''}')),
                        icon: const Icon(PhosphorIconsFill.phone, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_currentStatus == 'ACCEPTED')
                    AppButton(
                      label: 'Start Trip',
                      onPressed: () async {
                        await prov.updateStatus(widget.booking['id'], 'en-route');
                        setState(() => _currentStatus = 'EN_ROUTE');
                      },
                    ),
                  if (_currentStatus == 'EN_ROUTE')
                    AppButton(
                      label: 'I Have Arrived',
                      onPressed: () async {
                        await prov.updateStatus(widget.booking['id'], 'arrived');
                        setState(() => _currentStatus = 'ARRIVED');
                      },
                    ),
                  if (_currentStatus == 'ARRIVED') ...[
                    AppTextField(
                      controller: _weightCtrl,
                      label: 'Actual Weight (kg)',
                      hint: 'Enter collected weight',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Complete Pickup',
                      onPressed: () async {
                        final w = double.tryParse(_weightCtrl.text) ?? 0;
                        if (w <= 0) return;
                        await prov.updateStatus(widget.booking['id'], 'complete', actualWeightKg: w);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
