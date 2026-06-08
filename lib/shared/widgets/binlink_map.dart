import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_assets.dart';

/// BinLink Map V4 — Maplibre GL + SmartMaps Vector Tiles.
///
/// This upgrade provides:
///   1. Vector rendering (smooth zoom, rotation, tilting)
///   2. SmartMaps Premium Styles (matched to Uber/Bolt aesthetic)
///   3. TomTom Routing overlays
///   4. High-performance animated symbols (no more marker jitter)
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

  final ll.LatLng initialPosition;
  final List<Map<String, dynamic>> collectors;
  final List<ll.LatLng> routePoints;
  final ll.LatLng? pickupPosition;
  final Function(MapLibreMapController)? onMapCreated;
  final bool myLocationEnabled;
  final EdgeInsets padding;
  final Function(Map<String, dynamic>)? onCollectorTap;
  final double initialZoom;
  final bool isNavigating;
  final ll.LatLng? myLocation;
  final double myHeading;

  @override
  State<BinLinkMap> createState() => BinLinkMapState();
}

class BinLinkMapState extends State<BinLinkMap> {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;

  @override
  void didUpdateWidget(covariant BinLinkMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleLoaded) {
      _updateMapLayers(oldWidget);
    }
  }

  void flyTo(ll.LatLng position, {double zoom = 15}) {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        zoom,
      ),
    );
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }

  void _onStyleLoaded() async {
    _styleLoaded = true;
    // Add images for markers
    await _controller?.addImage('truck-icon', await _loadAssetImage(AppAssets.truck));
    await _controller?.addImage('pickup-pin', await _loadAssetImage(AppAssets.pin));
    
    _updateMapLayers(null);
  }

  Future<Uint8List> _loadAssetImage(String assetPath) async {
    final byteData = await DefaultAssetBundle.of(context).load(assetPath);
    return byteData.buffer.asUint8List();
  }

  void _updateMapLayers(BinLinkMap? oldWidget) {
    if (_controller == null) return;

    // ── Update Route Polyline ──
    if (widget.routePoints != oldWidget?.routePoints) {
      _drawRoute();
    }

    // ── Update Collector Markers ──
    if (widget.collectors != oldWidget?.collectors) {
      _updateCollectors();
    }

    // ── Update Pickup Pin ──
    if (widget.pickupPosition != oldWidget?.pickupPosition) {
      _updatePickupPin();
    }

    // ── Update Navigation State ──
    if (widget.isNavigating && widget.myLocation != null) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.myLocation!.latitude, widget.myLocation!.longitude),
            zoom: 17.5,
            bearing: widget.myHeading,
            tilt: 45,
          ),
        ),
      );
    }
  }

  void _drawRoute() async {
    const layerId = 'route-line';
    const sourceId = 'route-source';

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (widget.routePoints.isEmpty) return;

    final coordinates = widget.routePoints
        .map((p) => [p.longitude, p.latitude])
        .toList();

    await _controller?.addSource(sourceId, GeojsonSourceProperties(
      data: {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': coordinates,
        },
      },
    ));

    await _controller?.addLineLayer(
      sourceId,
      layerId,
      LineLayerProperties(
        lineColor: AppColors.primary.toHexShortString(),
        lineWidth: 5.0,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );
  }

  void _updateCollectors() async {
    const layerId = 'collector-layer';
    const sourceId = 'collector-source';

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (widget.collectors.isEmpty) return;

    final features = widget.collectors.map((c) {
      final lat = (c['lastLat'] as num?)?.toDouble() ?? 0.0;
      final lng = (c['lastLng'] as num?)?.toDouble() ?? 0.0;
      final bearing = (c['bearing'] as num?)?.toDouble() ?? 0.0;

      return {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [lng, lat],
        },
        'properties': {
          'id': c['id'],
          'bearing': bearing,
        },
      };
    }).toList();

    await _controller?.addSource(sourceId, GeojsonSourceProperties(
      data: {
        'type': 'FeatureCollection',
        'features': features,
      },
    ));

    await _controller?.addSymbolLayer(
      sourceId,
      layerId,
      SymbolLayerProperties(
        iconImage: 'truck-icon',
        iconRotate: ['get', 'bearing'],
        iconSize: 0.5,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
  }

  void _updatePickupPin() async {
    const layerId = 'pickup-layer';
    const sourceId = 'pickup-source';

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (widget.pickupPosition == null) return;

    await _controller?.addSource(sourceId, GeojsonSourceProperties(
      data: {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [widget.pickupPosition!.longitude, widget.pickupPosition!.latitude],
        },
      },
    ));

    await _controller?.addSymbolLayer(
      sourceId,
      layerId,
      const SymbolLayerProperties(
        iconImage: 'pickup-pin',
        iconSize: 0.8,
        iconAllowOverlap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final encodedKey = Uri.encodeComponent(Env.smartmapsApiKey);
    final styleUrl = 'https://tiles.smartmaps.cloud/styles/v1/smartmaps/dark/style.json?apiKey=$encodedKey';

    return MapLibreMap(
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialPosition.latitude, widget.initialPosition.longitude),
        zoom: widget.initialZoom,
      ),
      styleString: styleUrl,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationRenderMode: MyLocationRenderMode.compass,
      myLocationTrackingMode: widget.isNavigating
          ? MyLocationTrackingMode.trackingGps
          : MyLocationTrackingMode.none,
      trackCameraPosition: true,
      onMapClick: (point, latlng) async {
        final features = await _controller?.queryRenderedFeatures(
          point,
          ['collector-layer'],
          null,
        );
        if (features != null && features.isNotEmpty) {
          final id = features.first['properties']['id'];
          final collector = widget.collectors.firstWhere((c) => c['id'] == id, orElse: () => {});
          if (collector.isNotEmpty) {
            widget.onCollectorTap?.call(collector);
          }
        }
      },
    );
  }
}

extension _ColorX on Color {
  String toHexShortString() {
    final argb = toARGB32();
    return '#${argb.toRadixString(16).substring(2)}';
  }
}
