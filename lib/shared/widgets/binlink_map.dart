import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../core/utils/map_style.dart';

/// BinLink Map — MapLibre GL + SmartMaps tiles.
///
/// Renders the full-screen map used across every map screen:
///   - Household home: online collector trucks visible like Bolt/Uber cars
///   - Tracking screen: live collector truck + green route polyline
///   - Booking step 4: pickup pin preview
///   - Collector home: collector's own position
///
/// Truck markers use assets/icons/booking/icons8-garbage-truck-50.png
/// rendered as MapLibre Symbol annotations on the SmartMaps tile layer.
class BinLinkMap extends StatefulWidget {
  const BinLinkMap({
    super.key,
    required this.initialPosition,
    this.collectors = const [],
    this.routePoints = const [],
    this.pickupPosition,
    this.onMapCreated,
    this.myLocationEnabled = true,
    this.padding = EdgeInsets.zero,
    this.onCollectorTap,
    this.initialZoom = 14.5,
  });

  /// Camera target on launch.
  final LatLng initialPosition;

  /// Online collectors shown as truck icons.
  /// Each map must contain: 'id', 'lastLat', 'lastLng'.
  /// Optional: 'eta' (int minutes), 'bearing' (double degrees).
  final List<Map<String, dynamic>> collectors;

  /// Green route polyline (collector → pickup, or multi-stop).
  final List<LatLng> routePoints;

  /// Optional static pickup pin shown as a green filled circle.
  final LatLng? pickupPosition;

  /// Fires once the controller is ready.
  final Function(MapLibreMapController)? onMapCreated;

  final bool myLocationEnabled;
  final EdgeInsets padding;

  /// Fires when user taps a truck icon — passes the collector map.
  final Function(Map<String, dynamic>)? onCollectorTap;

  final double initialZoom;

  @override
  State<BinLinkMap> createState() => _BinLinkMapState();
}

class _BinLinkMapState extends State<BinLinkMap> {
  MapLibreMapController? _ctrl;
  bool _truckImageReady = false;
  final List<Symbol> _truckSymbols = [];
  Line? _routeLine;
  Circle? _pickupCircle;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _ctrl?.onSymbolTapped.remove(_onSymbolTapped);
    super.dispose();
  }

  @override
  void didUpdateWidget(BinLinkMap old) {
    super.didUpdateWidget(old);
    if (_ctrl == null || !_truckImageReady) return;
    _syncCollectors();
    if (widget.routePoints != old.routePoints) _syncRoute();
    if (widget.pickupPosition != old.pickupPosition) _syncPickupPin();
  }

  // ── MapLibre callbacks ────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _ctrl = controller;
    controller.onSymbolTapped.add(_onSymbolTapped);
    widget.onMapCreated?.call(controller);
  }

  Future<void> _onStyleLoaded() async {
    await _registerTruckImage();
    _syncCollectors();
    _syncRoute();
    _syncPickupPin();
  }

  // ── Image registration ────────────────────────────────────────────────────

  Future<void> _registerTruckImage() async {
    if (_truckImageReady || _ctrl == null) return;
    try {
      final data = await rootBundle.load(
        'assets/icons/booking/icons8-garbage-truck-50.png',
      );
      final bytes = data.buffer.asUint8List();
      await _ctrl!.addImage('bl_truck', bytes);
      _truckImageReady = true;
    } catch (e) {
      debugPrint('[BinLinkMap] truck image load failed: $e');
    }
  }

  // ── Collector truck symbols ───────────────────────────────────────────────

  Future<void> _syncCollectors() async {
    final ctrl = _ctrl;
    if (ctrl == null || !_truckImageReady) return;

    for (final sym in List<Symbol>.from(_truckSymbols)) {
      try { await ctrl.removeSymbol(sym); } catch (_) {}
    }
    _truckSymbols.clear();

    for (final c in widget.collectors) {
      final lat = (c['lastLat'] as num?)?.toDouble();
      final lng = (c['lastLng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final eta = (c['eta'] as num?)?.round();
      final etaLabel = eta != null ? '$eta min' : '';

      try {
        final sym = await ctrl.addSymbol(SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: 'bl_truck',
          iconSize: 1.8,
          iconAnchor: 'center',
          iconRotate: (c['bearing'] as num?)?.toDouble() ?? 0,
          textField: etaLabel,
          textSize: 11.0,
          textColor: '#111111',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2.0,
          textOffset: const Offset(0, 2.8),
          textAnchor: 'top',
        ));
        _truckSymbols.add(sym);
      } catch (e) {
        debugPrint('[BinLinkMap] addSymbol failed: $e');
      }
    }
  }

  void _onSymbolTapped(Symbol tapped) {
    if (widget.onCollectorTap == null) return;
    final pos = tapped.options.geometry;
    if (pos == null) return;
    for (final c in widget.collectors) {
      final lat = (c['lastLat'] as num?)?.toDouble() ?? 0.0;
      final lng = (c['lastLng'] as num?)?.toDouble() ?? 0.0;
      if ((lat - pos.latitude).abs() < 0.0002 &&
          (lng - pos.longitude).abs() < 0.0002) {
        widget.onCollectorTap!(c);
        return;
      }
    }
  }

  // ── Route polyline ────────────────────────────────────────────────────────

  Future<void> _syncRoute() async {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    if (_routeLine != null) {
      try { await ctrl.removeLine(_routeLine!); } catch (_) {}
      _routeLine = null;
    }
    if (widget.routePoints.length < 2) return;
    try {
      _routeLine = await ctrl.addLine(LineOptions(
        geometry: widget.routePoints,
        lineColor: '#16A34A',
        lineWidth: 4.5,
        lineOpacity: 0.92,
        lineJoin: 'round',
      ));
    } catch (e) {
      debugPrint('[BinLinkMap] addLine failed: $e');
    }
  }

  // ── Pickup pin (green filled circle) ─────────────────────────────────────

  Future<void> _syncPickupPin() async {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    if (_pickupCircle != null) {
      try { await ctrl.removeCircle(_pickupCircle!); } catch (_) {}
      _pickupCircle = null;
    }
    final pos = widget.pickupPosition;
    if (pos == null) return;
    try {
      _pickupCircle = await ctrl.addCircle(CircleOptions(
        geometry: pos,
        circleRadius: 10.0,
        circleColor: '#16A34A',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.5,
        circleOpacity: 1.0,
      ));
    } catch (e) {
      debugPrint('[BinLinkMap] addCircle failed: $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void flyTo(LatLng position, {double zoom = 15}) {
    _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: kMapStyleUrl,
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: widget.initialZoom,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      myLocationRenderMode: MyLocationRenderMode.compass,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      logoViewMargins: Point(8, widget.padding.bottom + 8),
      attributionButtonMargins: Point(8, widget.padding.bottom + 8),
    );
  }
}
