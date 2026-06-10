import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';

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
    try {
      await _controller?.addImage('truck-icon', await _makeTruckIcon());
      await _controller?.addImage('pickup-pin', await _makePickupPin());
    } catch (e) {
      debugPrint('[Map] Failed to add marker icons: $e');
    }
    _updateMapLayers(null);
  }

  /// Programmatically renders a circular collector marker (Bolt-style).
  Future<Uint8List> _makeTruckIcon() async {
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    const cx = size / 2;
    const cy = size / 2;
    const r  = size / 2 - 2;

    // Drop shadow
    canvas.drawCircle(
      const Offset(cx, cy + 2),
      r,
      Paint()..color = Colors.black.withAlpha(40)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Filled circle — primary color
    canvas.drawCircle(
      const Offset(cx, cy),
      r,
      Paint()..color = AppColors.primary,
    );

    // White border
    canvas.drawCircle(
      const Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // White directional arrow (pointing up = north bearing=0)
    final arrow = Path()
      ..moveTo(cx,      cy - 12) // tip
      ..lineTo(cx - 9,  cy + 10)
      ..lineTo(cx,      cy + 4)
      ..lineTo(cx + 9,  cy + 10)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final img  = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Programmatically renders a pickup location pin.
  Future<Uint8List> _makePickupPin() async {
    const size = 56.0;
    const cx = size / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final paint = Paint()..color = AppColors.success;

    // Circle head
    canvas.drawCircle(const Offset(cx, 18), 14, paint);

    // Pin tail
    final tail = Path()
      ..moveTo(cx - 10, 26)
      ..quadraticBezierTo(cx, 50, cx, 50)
      ..quadraticBezierTo(cx, 50, cx + 10, 26)
      ..close();
    canvas.drawPath(tail, paint);

    // White inner dot
    canvas.drawCircle(const Offset(cx, 18), 5, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final img  = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void _updateMapLayers(BinLinkMap? oldWidget) {
    if (_controller == null || !_styleLoaded) return;
    try {
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
    } catch (e) {
      debugPrint('[Map] Error updating layers: $e');
    }
  }

  void _drawRoute() async {
    if (_controller == null || !_styleLoaded) return;
    const layerId = 'route-line';
    const sourceId = 'route-source';

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (widget.routePoints.isEmpty) return;

    try {
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
    } catch (e) {
      debugPrint('[Map] Error drawing route: $e');
    }
  }

  void _updateCollectors() async {
    if (_controller == null || !_styleLoaded) return;
    const layerId = 'collector-layer';
    const sourceId = 'collector-source';

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (widget.collectors.isEmpty) return;

    try {
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
    } catch (e) {
      debugPrint('[Map] Error updating collectors: $e');
    }
  }

  void _updatePickupPin() async {
    if (_controller == null || !_styleLoaded) return;
    const layerId = 'pickup-layer';
    const sourceId = 'pickup-source';

    // Cache before any await — parent widget may rebuild with null during async gaps
    final pos = widget.pickupPosition;

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (pos == null) return;

    try {
      await _controller?.addSource(sourceId, GeojsonSourceProperties(
        data: {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [pos.longitude, pos.latitude],
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
    } catch (e) {
      debugPrint('[Map] Error updating pickup pin: $e');
    }
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
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
