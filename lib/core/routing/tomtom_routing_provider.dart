import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../config/env.dart';
import 'routing_provider.dart';

/// TomTom Routing API provider — second-tier fallback.
class TomTomRoutingProvider implements RoutingProvider {
  TomTomRoutingProvider();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get name => 'TomTom';

  @override
  bool get isAvailable => Env.tomtomApiKey.isNotEmpty;

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    if (!isAvailable) return null;
    try {
      final resp = await _dio.get(
        'https://api.tomtom.com/routing/1/calculateRoute/'
        '${origin.latitude},${origin.longitude}:'
        '${dest.latitude},${dest.longitude}/json',
        queryParameters: {
          'key':                 Env.tomtomApiKey,
          'travelMode':          'van',
          'routeRepresentation': 'polyline',
          'instructionsType':    'none',
          'traffic':             'false',
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
        points:         points,
        travelTimeSec:  (summary['travelTimeInSeconds'] as num?)?.toInt() ?? 0,
        distanceMeters: (summary['lengthInMeters']      as num?)?.toInt() ?? 0,
        providerName:   name,
      );
    } catch (_) {
      return null;
    }
  }
}
