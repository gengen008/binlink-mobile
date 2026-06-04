import 'package:dio/dio.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../config/env.dart';
import 'routing_provider.dart';

/// OSRM (Open Source Routing Machine) provider.
///
/// Uses the public demo server by default; set OSRM_BASE_URL in .env to point
/// at a self-hosted instance (recommended for production loads).
///
/// Response format: OSRM route geometry encoded as Google polyline.
class OsrmRoutingProvider implements RoutingProvider {
  OsrmRoutingProvider();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
  ));

  @override
  String get name => 'OSRM';

  @override
  bool get isAvailable => true; // no API key required

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    try {
      final base = Env.osrmBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final coord = '${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}';

      final resp = await _dio.get(
        '$base/route/v1/driving/$coord',
        queryParameters: {
          'overview':    'full',
          'geometries':  'polyline',
          'annotations': 'false',
        },
      );

      if (resp.data['code'] != 'Ok') return null;

      final routes = (resp.data['routes'] as List?) ?? [];
      if (routes.isEmpty) return null;

      final route    = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as String? ?? '';
      final points   = _decodePolyline(geometry);
      if (points.isEmpty) return null;

      final duration = (route['duration'] as num?)?.toInt() ?? 0;
      final distance = (route['distance'] as num?)?.toInt() ?? 0;

      return RouteResult(
        points:         points,
        travelTimeSec:  duration,
        distanceMeters: distance,
        providerName:   name,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decode a Google-encoded polyline string into a list of LatLng points.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
