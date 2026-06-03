import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../config/env.dart';

class RouteResult {
  final List<LatLng> points;
  final int travelTimeSec;
  final int distanceMeters;

  const RouteResult({
    required this.points,
    required this.travelTimeSec,
    required this.distanceMeters,
  });
}

class RoutingService {
  RoutingService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static String get _key => Env.tomtomApiKey;
  static bool get _hasKey => _key.isNotEmpty;

  /// Calculate route from [origin] to [dest] using TomTom Routing API.
  /// Returns null if no API key or request fails.
  static Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    if (!_hasKey) return null;
    try {
      final resp = await _dio.get(
        'https://api.tomtom.com/routing/1/calculateRoute/'
        '${origin.latitude},${origin.longitude}:'
        '${dest.latitude},${dest.longitude}/json',
        queryParameters: {
          'key':                  _key,
          'travelMode':           'van',
          'routeRepresentation':  'polyline',
          'instructionsType':     'none',
          'traffic':              'false',
        },
      );
      final routes = (resp.data['routes'] as List?) ?? [];
      if (routes.isEmpty) return null;
      final route   = routes.first as Map<String, dynamic>;
      final summary = route['summary'] as Map<String, dynamic>? ?? {};
      final legs    = (route['legs'] as List?) ?? [];
      final points  = <LatLng>[];
      for (final leg in legs) {
        for (final pt in (leg['points'] as List? ?? [])) {
          final pLat = (pt['latitude']  as num?)?.toDouble();
          final pLng = (pt['longitude'] as num?)?.toDouble();
          if (pLat != null && pLng != null) points.add(LatLng(pLat, pLng));
        }
      }
      return RouteResult(
        points:          points,
        travelTimeSec:   (summary['travelTimeInSeconds'] as num?)?.toInt() ?? 0,
        distanceMeters:  (summary['lengthInMeters']      as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
