import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_assets.dart';

/// BinLink Map — flutter_map + SmartMaps tiles.
/// 
/// Replaces MapLibre implementation to remove Mapbox entirely.
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
    this.isNavigating = false,
    this.myLocation,
    this.myHeading = 0.0,
  });

  final LatLng initialPosition;
  final List<Map<String, dynamic>> collectors;
  final List<LatLng> routePoints;
  final LatLng? pickupPosition;
  final Function(MapController)? onMapCreated;
  final bool myLocationEnabled;
  final EdgeInsets padding;
  final Function(Map<String, dynamic>)? onCollectorTap;
  final double initialZoom;
  final bool isNavigating;
  final LatLng? myLocation;
  final double myHeading;

  @override
  State<BinLinkMap> createState() => BinLinkMapState();
}

class BinLinkMapState extends State<BinLinkMap> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimatedMapController _animatedMapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
    );
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BinLinkMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNavigating && widget.myLocation != null) {
      if (oldWidget.myLocation != widget.myLocation || oldWidget.myHeading != widget.myHeading) {
        _animatedMapController.animateTo(
          dest: widget.myLocation!,
          zoom: 17.5,
          rotation: widget.myHeading,
        );
      }
    }
  }

  void flyTo(LatLng position, {double zoom = 15}) {
    _animatedMapController.animateTo(dest: position, zoom: zoom);
  }

  @override
  Widget build(BuildContext context) {
    // Read API key from dotenv (loaded at startup in main) — falls back to OSM if missing
    final smartmapsKey = dotenv.env['SMARTMAPS_API_KEY'] ?? '';
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialPosition,
        initialZoom: widget.initialZoom,
        maxZoom: 19.0,
        minZoom: 5.0,
        onMapReady: () {
          widget.onMapCreated?.call(_mapController);
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // ── Smartmaps Tile Layer ──
        TileLayer(
          urlTemplate: 'https://tiles.smartmaps.net/v1/{z}/{x}/{y}.png?key=$smartmapsKey',
          userAgentPackageName: 'eco.binlink.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // fallback if key empty
        ),
        
        // ── Route Polyline ──
        if (widget.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints,
                color: AppColors.primary,
                strokeWidth: 4.5,
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ── Collector Truck Markers ──
        _AnimatedCollectorLayer(
          collectors: widget.collectors,
          onTap: widget.onCollectorTap,
        ),

        // ── Pickup Pin ──
        if (widget.pickupPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.pickupPosition!,
                width: 32,
                height: 32,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 2.5)),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AnimatedCollectorLayer extends StatefulWidget {
  const _AnimatedCollectorLayer({required this.collectors, this.onTap});
  final List<Map<String, dynamic>> collectors;
  final Function(Map<String, dynamic>)? onTap;

  @override
  State<_AnimatedCollectorLayer> createState() => _AnimatedCollectorLayerState();
}

class _AnimatedCollectorLayerState extends State<_AnimatedCollectorLayer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Map<String, LatLng> _oldPositions = {};
  Map<String, LatLng> _newPositions = {};
  Map<String, double> _bearings = {};
  Map<String, int> _etas = {};

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _updateData(widget.collectors, animate: false);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCollectorLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateData(widget.collectors, animate: true);
  }

  void _updateData(List<Map<String, dynamic>> cols, {bool animate = false}) {
    _oldPositions = Map.from(_newPositions);
    _newPositions.clear();
    _bearings.clear();
    _etas.clear();

    for (final c in cols) {
      final id = c['id']?.toString() ?? c.hashCode.toString();
      final lat = (c['lastLat'] as num?)?.toDouble() ?? 0.0;
      final lng = (c['lastLng'] as num?)?.toDouble() ?? 0.0;
      final pos = LatLng(lat, lng);

      _newPositions[id] = pos;
      if (!_oldPositions.containsKey(id)) {
        _oldPositions[id] = pos; // prevent jumping from 0,0 on first appearance
      }
      
      _bearings[id] = (c['bearing'] as num?)?.toDouble() ?? 0.0;
      final eta = (c['eta'] as num?)?.round();
      if (eta != null) _etas[id] = eta;
    }

    if (animate && mounted) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);

        return MarkerLayer(
          markers: _newPositions.keys.map((id) {
            final oldPos = _oldPositions[id]!;
            final newPos = _newPositions[id]!;
            final bearing = _bearings[id] ?? 0.0;
            final eta = _etas[id];

            final lat = oldPos.latitude + (newPos.latitude - oldPos.latitude) * t;
            final lng = oldPos.longitude + (newPos.longitude - oldPos.longitude) * t;

            final cData = widget.collectors.firstWhere((c) => (c['id']?.toString() ?? c.hashCode.toString()) == id);

            return Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 70,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => widget.onTap?.call(cData),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eta != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text('$eta min', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Transform.rotate(
                      angle: bearing * pi / 180,
                      child: Image.asset(AppAssets.truck, width: 32, height: 32),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
