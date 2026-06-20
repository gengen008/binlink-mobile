import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/config/env.dart';
import '../../core/config/app_flavor.dart';
import '../../core/design_system/collector_design_system.dart';
import '../../core/design_system/household_design_system.dart';

class MapStyleResolver {
  MapStyleResolver._();

  static const fallbackStyleUrl = 'https://tiles.openfreemap.org/styles/dark';
  static String? _resolved;
  static Future<String>? _inFlight;

  static Future<String> resolve() {
    if (_resolved != null) return Future.value(_resolved);
    return _inFlight ??= _probe();
  }

  static Future<String> _probe() async {
    final key = Env.smartmapsApiKey;
    if (key.isNotEmpty) {
      final url = 'https://tiles.smartmaps.cloud/styles/v1/smartmaps/dark/style.json?apiKey=${Uri.encodeComponent(key)}';
      try {
        final res = await Dio().get<void>(
          url,
          options: Options(
            receiveTimeout: const Duration(seconds: 6),
            sendTimeout: const Duration(seconds: 6),
            validateStatus: (s) => true,
          ),
        );
        if (res.statusCode == 200) {
          _resolved = url;
          return url;
        }
      } catch (e) {
        debugPrint('[Map] SmartMaps style probe failed: $e');
      }
    }
    _resolved = fallbackStyleUrl;
    return fallbackStyleUrl;
  }
}

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
  String? _styleUrl;

  @override
  void initState() {
    super.initState();
    MapStyleResolver.resolve().then((url) {
      if (mounted) setState(() => _styleUrl = url);
    });
  }

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

  Future<Uint8List> _loadAssetImage(String path, {int width = 120}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final fi = await codec.getNextFrame();
    final imgData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return imgData!.buffer.asUint8List();
  }

  void _onStyleLoaded() async {
    _styleLoaded = true;
    try {
      await _controller?.addImage('truck-icon', await _loadAssetImage(FlavorConfig.isCollector ? CollectorAssets.truckMarker : HouseholdAssets.truckMarker, width: 140));
      await _controller?.addImage('pickup-pin', await _loadAssetImage(FlavorConfig.isCollector ? CollectorAssets.pickupMarker : HouseholdAssets.pickupMarker, width: 120));
    } catch (e) {
      debugPrint('[Map] Failed to add branded markers: $e');
    }
    _updateMapLayers(null);
  }

  void _updateMapLayers(BinLinkMap? oldWidget) {
    if (_controller == null || !_styleLoaded) return;
    try {
      if (widget.routePoints != oldWidget?.routePoints) _drawRoute();
      if (widget.collectors != oldWidget?.collectors) _updateCollectors();
      if (widget.pickupPosition != oldWidget?.pickupPosition) _updatePickupPin();
      
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
      final coordinates = widget.routePoints.map((p) => [p.longitude, p.latitude]).toList();

      await _controller?.addSource(sourceId, GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': <String, dynamic>{},
              'geometry': {
                'type': 'LineString',
                'coordinates': coordinates,
              },
            },
          ],
        },
      ));

      await _controller?.addLineLayer(
        sourceId,
        layerId,
        LineLayerProperties(
          lineColor: (FlavorConfig.isCollector ? CollectorColors.green : HouseholdColors.primary).toHexShortString(),
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
      final features = <Map<String, dynamic>>[];
      for (final c in widget.collectors) {
        final lat = (c['lastLat'] as num?)?.toDouble();
        final lng = (c['lastLng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
          'properties': {
            'id': c['id'],
            'bearing': (c['bearing'] as num?)?.toDouble() ?? 0.0,
          },
        });
      }

      await _controller?.addSource(sourceId, GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': features,
        },
      ));

      await _controller?.addSymbolLayer(
        sourceId,
        layerId,
        const SymbolLayerProperties(
          iconImage: 'truck-icon',
          iconSize: 0.6,
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

    final pos = widget.pickupPosition;

    try {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);
    } catch (_) {}

    if (pos == null) return;

    try {
      await _controller?.addSource(sourceId, GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': <String, dynamic>{},
              'geometry': {
                'type': 'Point',
                'coordinates': [pos.longitude, pos.latitude],
              },
            },
          ],
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
    final styleUrl = _styleUrl;
    if (styleUrl == null) {
      return Container(color: FlavorConfig.isCollector ? CollectorColors.dark : HouseholdColors.sand);
    }

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
