import 'dart:async';
import 'dart:math' show max;
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
import '../../../core/l10n/strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/status_badge.dart';

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
  LatLng? _collectorPos;
  Circle? _collectorDot;
  Line? _routeLine;
  String? _etaLabel;
  String? _distLabel;
  DateTime? _lastRouteFetch;

  // Track whether we have done the initial route overview fit
  bool _initialFitDone = false;

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

  // ── Map init ───────────────────────────────────────────────────────────────

  Future<void> _onMapStyleLoaded() async {
    if (_mapCtrl == null) return;

    // Pickup destination — large green circle so it stands out on the map
    await _mapCtrl!.addCircle(CircleOptions(
      geometry: _pickupPos,
      circleRadius: 22,
      circleColor: '#16A34A',
      circleOpacity: 1.0,
      circleStrokeWidth: 4,
      circleStrokeColor: '#FFFFFF',
      circleStrokeOpacity: 1.0,
    ));

    // Second ring to make destination even more visible
    await _mapCtrl!.addCircle(CircleOptions(
      geometry: _pickupPos,
      circleRadius: 38,
      circleColor: '#16A34A',
      circleOpacity: 0.18,
      circleStrokeWidth: 0,
      circleStrokeOpacity: 0.0,
    ));

    _startLocationStream();
  }

  void _startLocationStream() {
    _locationSub = LocationService.getPositionStream().listen((pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      _updateCollectorMarker(latLng);
      _maybeRefreshRoute(latLng);
      if (mounted) setState(() => _collectorPos = latLng);
    });
  }

  Future<void> _updateCollectorMarker(LatLng pos) async {
    if (_mapCtrl == null) return;
    if (_collectorDot == null) {
      _collectorDot = await _mapCtrl!.addCircle(CircleOptions(
        geometry: pos,
        circleRadius: 12,
        circleColor: '#5483B3',
        circleOpacity: 1.0,
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
        circleStrokeOpacity: 1.0,
      ));
    } else {
      await _mapCtrl!
          .updateCircle(_collectorDot!, CircleOptions(geometry: pos));
    }

    if (!_initialFitDone) {
      // First GPS fix: zoom out to show BOTH collector and pickup destination
      _initialFitDone = true;
      await _fitBothPoints(pos);
    } else {
      // Subsequent updates: follow collector with smooth camera
      await _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(pos, 15.0));
    }
  }

  /// Fit camera to show both the collector's current position and the pickup
  /// destination, similar to how Bolt/Uber shows the full route on accept.
  Future<void> _fitBothPoints([LatLng? collectorOverride]) async {
    if (_mapCtrl == null) return;
    final cPos = collectorOverride ?? _collectorPos;
    if (cPos == null) {
      // No GPS fix yet — just show pickup destination
      await _mapCtrl!.animateCamera(
          CameraUpdate.newLatLngZoom(_pickupPos, 14.0));
      return;
    }

    final latA = cPos.latitude;
    final latB = _pickupPos.latitude;
    final lngA = cPos.longitude;
    final lngB = _pickupPos.longitude;

    final centerLat = (latA + latB) / 2;
    final centerLng = (lngA + lngB) / 2;

    // Distance-based zoom selection
    final dlat = (latA - latB).abs();
    final dlng = (lngA - lngB).abs();
    final maxDelta = max(dlat, dlng);

    final double zoom;
    if (maxDelta < 0.005) {
      zoom = 15.5;
    } else if (maxDelta < 0.01) {
      zoom = 15.0;
    } else if (maxDelta < 0.03) {
      zoom = 13.5;
    } else if (maxDelta < 0.08) {
      zoom = 12.5;
    } else if (maxDelta < 0.2) {
      zoom = 11.5;
    } else {
      zoom = 10.0;
    }

    await _mapCtrl!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), zoom),
    );
  }

  Future<void> _maybeRefreshRoute(LatLng pos) async {
    final now = DateTime.now();
    final shouldFetch = _lastRouteFetch == null ||
        now.difference(_lastRouteFetch!).inSeconds >= 30;
    if (!shouldFetch || _mapCtrl == null) return;
    _lastRouteFetch = now;

    final result = await RoutingService.getRoute(pos, _pickupPos);
    if (!mounted || _mapCtrl == null) return;

    if (_routeLine == null) {
      _routeLine = await _mapCtrl!.addLine(LineOptions(
        geometry: result.points,
        lineColor: '#5483B3',
        lineWidth: 4.5,
        lineOpacity: 0.92,
      ));
    } else {
      await _mapCtrl!
          .updateLine(_routeLine!, LineOptions(geometry: result.points));
    }

    if (mounted) {
      setState(() {
        _etaLabel = result.etaLabel;
        _distLabel = '${result.distanceKm.toStringAsFixed(1)} km';
      });
    }
  }

  // ── Navigate externally (Google Maps) ─────────────────────────────────────

  Future<void> _navigateToPickup() async {
    final lat = _pickupPos.latitude;
    final lng = _pickupPos.longitude;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Status action handlers ─────────────────────────────────────────────────

  Future<void> _handleEnRoute(
      CollectorProvider prov, String bookingId) async {
    await prov.updateStatus(bookingId, 'en-route');
    if (mounted) setState(() => _currentStatus = 'EN_ROUTE');
  }

  Future<void> _handleArrived(
      CollectorProvider prov, String bookingId) async {
    await prov.updateStatus(bookingId, 'arrived');
    if (mounted) setState(() => _currentStatus = 'ARRIVED');
  }

  Future<void> _handleComplete(
    BuildContext ctx,
    CollectorProvider prov,
    String bookingId,
  ) async {
    final weightStr = _weightCtrl.text.trim();
    if (weightStr.isEmpty) {
      _snack(ctx, 'Enter the actual weight to complete', AppColors.warning);
      return;
    }
    final actualWeight = double.tryParse(weightStr);
    if (actualWeight == null || actualWeight <= 0) {
      _snack(ctx, 'Enter a valid weight in kg', AppColors.warning);
      return;
    }
    await prov.updateStatus(bookingId, 'complete',
        actualWeightKg: actualWeight);
    if (!ctx.mounted) return;
    setState(() => _currentStatus = 'COMPLETED');
    _snack(ctx, 'Pickup completed! Great work!', AppColors.success);
    Navigator.pop(ctx);
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Exception sheet ────────────────────────────────────────────────────────

  void _showExceptionSheet(String bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExceptionSheet(
        onSubmit: (reason, note) {
          context.read<CollectorProvider>().reportException(
              bookingId, reason, note);
          Navigator.pop(context);
          _snack(context, 'Exception reported. Household notified.',
              AppColors.warning);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final bookingId = widget.booking['id'] as String;
    final address = widget.booking['pickupAddress'] as String? ?? '';
    final amount = Fmt.toDouble(widget.booking['totalAmount']);
    final hhPhone = widget.booking['household']?['phone'] as String?;
    final hhName =
        widget.booking['household']?['fullName'] as String? ?? 'Household';
    final isActive =
        ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(_currentStatus);
    final sheetH = _bottomSheetHeight(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ──
          Positioned.fill(
            child: MapLibreMap(
              styleString: kMapStyleUrl,
              initialCameraPosition: CameraPosition(
                target: _pickupPos,
                zoom: 14.0,
              ),
              onMapCreated: (c) => _mapCtrl = c,
              onStyleLoadedCallback: _onMapStyleLoaded,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              doubleClickZoomEnabled: false,
              myLocationEnabled: false,
              compassEnabled: false,
            ),
          ),

          // ── Top header bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.secondary),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Active Pickup',
                              style: AppTextStyles.appBarTitle
                                  .copyWith(color: AppColors.secondary)),
                          if (address.isNotEmpty)
                            Text(
                              address,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.steelBlue,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(status: _currentStatus, animate: true),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => showChatSheet(
                        context,
                        bookingId: bookingId,
                        myRole: 'COLLECTOR',
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.steelBlue.withAlpha(60)),
                        ),
                        child: const Icon(PhosphorIconsFill.chatCircle,
                            color: AppColors.steelBlue, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── ETA + distance chip ──
          if (_etaLabel != null)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsFill.clock,
                          color: AppColors.iceBlue, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _etaLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      if (_distLabel != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 14,
                          color: Colors.white.withAlpha(60),
                        ),
                        const SizedBox(width: 10),
                        const Icon(PhosphorIconsFill.navigationArrow,
                            color: AppColors.skyBlue, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _distLabel!,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── FAB column: fit-route + navigate ──
          Positioned(
            right: 16,
            bottom: sheetH + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fit-route overview button (shows full route like Bolt/Uber)
                GestureDetector(
                  onTap: () => _fitBothPoints(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.arrowsOut,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Navigate button — opens Google Maps for turn-by-turn
                GestureDetector(
                  onTap: _navigateToPickup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsFill.navigationArrow,
                            color: Colors.white, size: 18),
                        SizedBox(width: 7),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom action sheet ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Household info card
                      _HouseholdCard(
                        hhName: hhName,
                        address: address,
                        amount: amount,
                        binSize:
                            widget.booking['binSize'] as String? ?? '',
                        paymentMethod:
                            widget.booking['paymentMethod'] as String? ??
                                '',
                        phone: hhPhone,
                      ),

                      const SizedBox(height: 16),

                      // Action buttons for current status
                      ..._buildActions(context, prov, bookingId),

                      // Exception report (always visible during active job)
                      if (isActive) ...[
                        const SizedBox(height: 12),
                        _ExceptionButton(
                            onTap: () => _showExceptionSheet(bookingId)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _bottomSheetHeight(BuildContext context) {
    switch (_currentStatus) {
      case 'ARRIVED':
        return 370;
      case 'COMPLETED':
        return 240;
      default:
        return 295;
    }
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  List<Widget> _buildActions(
    BuildContext context,
    CollectorProvider prov,
    String bookingId,
  ) {
    switch (_currentStatus) {
      case 'ACCEPTED':
        return [
          AppButton(
            label: S.of(context).startRoute,
            onPressed: () => _handleEnRoute(prov, bookingId),
            icon: const Icon(PhosphorIconsFill.navigationArrow,
                color: AppColors.white, size: 20),
          ),
        ];

      case 'EN_ROUTE':
        return [
          AppButton(
            label: S.of(context).markArrived,
            onPressed: () => _handleArrived(prov, bookingId),
            icon: const Icon(PhosphorIconsFill.mapPin,
                color: AppColors.white, size: 20),
          ),
        ];

      case 'ARRIVED':
        return [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.lgBR,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.scales,
                        color: AppColors.skyBlue, size: 15),
                    const SizedBox(width: 6),
                    const Text('Actual Weight (kg)',
                        style: AppTextStyles.label),
                    const SizedBox(width: 4),
                    Text('*required',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.mono,
                  decoration: InputDecoration(
                    hintText: 'e.g. 85',
                    hintStyle: AppTextStyles.caption,
                    suffixText: 'kg',
                    suffixStyle: AppTextStyles.caption
                        .copyWith(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdBR,
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBR,
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBR,
                      borderSide:
                          const BorderSide(color: AppColors.steelBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: S.of(context).completePickup,
            onPressed: () => _handleComplete(context, prov, bookingId),
            icon: const Icon(PhosphorIconsFill.checkCircle,
                color: AppColors.white, size: 20),
          ),
        ];

      case 'COMPLETED':
        return [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: AppRadius.xlBR,
              border: Border.all(color: AppColors.success.withAlpha(60)),
            ),
            child: const Row(
              children: [
                Icon(PhosphorIconsFill.checkCircle,
                    color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Pickup completed successfully!',
                      style: AppTextStyles.h4),
                ),
              ],
            ),
          ),
        ];

      default:
        return [];
    }
  }
}

// ── Household card ─────────────────────────────────────────────────────────────

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({
    required this.hhName,
    required this.address,
    required this.amount,
    required this.binSize,
    required this.paymentMethod,
    this.phone,
  });
  final String hhName;
  final String address;
  final double amount;
  final String binSize;
  final String paymentMethod;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    Fmt.initials(hhName),
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hhName, style: AppTextStyles.h4),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin,
                            color: AppColors.skyBlue, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(address,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (phone != null)
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.success.withAlpha(80)),
                    ),
                    child: const Icon(PhosphorIconsFill.phone,
                        color: AppColors.success, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: Fmt.binSizeLabel(binSize),
                icon: PhosphorIconsFill.trashSimple,
                color: AppColors.steelBlue,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                label: Fmt.currency(amount),
                icon: PhosphorIconsFill.coins,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                label: Fmt.paymentMethodLabel(paymentMethod),
                icon: PhosphorIconsRegular.deviceMobile,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Exception button ───────────────────────────────────────────────────────────

class _ExceptionButton extends StatelessWidget {
  const _ExceptionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(12),
          borderRadius: AppRadius.lgBR,
          border: Border.all(color: AppColors.danger.withAlpha(80)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.warning,
                color: AppColors.danger, size: 16),
            SizedBox(width: 8),
            Text(
              'Report Exception',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exception sheet ────────────────────────────────────────────────────────────

class _ExceptionSheet extends StatefulWidget {
  const _ExceptionSheet({required this.onSubmit});
  final void Function(String reason, String? note) onSubmit;

  @override
  State<_ExceptionSheet> createState() => _ExceptionSheetState();
}

class _ExceptionSheetState extends State<_ExceptionSheet> {
  String? _selectedReason;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  static const _reasons = [
    ('GATE_LOCKED', 'Gate Locked', PhosphorIconsRegular.lock),
    ('BIN_NOT_READY', 'Bin Not Ready', PhosphorIconsRegular.trashSimple),
    ('OVERLOADED', 'Overfilled / Overloaded', PhosphorIconsRegular.warning),
    ('HAZARDOUS', 'Hazardous Material', PhosphorIconsRegular.skull),
    ('NO_ACCESS', 'No Access to Property', PhosphorIconsRegular.prohibit),
    ('OTHER', 'Other', PhosphorIconsRegular.dotsSixVertical),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.sheetBR,
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.fullBR,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(25),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.danger.withAlpha(80)),
                ),
                child: const Icon(PhosphorIconsFill.warning,
                    color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report Exception', style: AppTextStyles.h3),
                  Text('What issue did you encounter?',
                      style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          ..._reasons.map((r) {
            final isSelected = _selectedReason == r.$1;
            return GestureDetector(
              onTap: () => setState(() => _selectedReason = r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.danger.withAlpha(20)
                      : AppColors.card,
                  borderRadius: AppRadius.lgBR,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.danger.withAlpha(140)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.$3,
                        color: isSelected
                            ? AppColors.danger
                            : AppColors.muted,
                        size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.$2,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.danger
                                : AppColors.textPrimary,
                          )),
                    ),
                    if (isSelected)
                      const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.danger, size: 18),
                  ],
                ),
              ),
            );
          }),
          if (_selectedReason == 'OTHER') ...[
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              style: AppTextStyles.bodyMedium,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: AppTextStyles.caption,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.lgBR,
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.lgBR,
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.lgBR,
                  borderSide:
                      const BorderSide(color: AppColors.steelBlue),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _selectedReason != null && !_submitting
                ? () {
                    setState(() => _submitting = true);
                    widget.onSubmit(
                      _selectedReason!,
                      _selectedReason == 'OTHER'
                          ? _noteCtrl.text.trim()
                          : null,
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: _selectedReason != null
                    ? AppColors.danger
                    : AppColors.card,
                borderRadius: AppRadius.xlBR,
                border: Border.all(
                  color: _selectedReason != null
                      ? AppColors.danger
                      : AppColors.border,
                ),
                boxShadow: _selectedReason != null
                    ? [
                        BoxShadow(
                          color: AppColors.danger.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedReason != null
                              ? AppColors.white
                              : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: color),
                textAlign: TextAlign.center,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}
