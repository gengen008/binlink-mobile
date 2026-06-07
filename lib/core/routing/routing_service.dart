import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'routing_provider.dart';
import 'tomtom_routing_provider.dart';
import 'osrm_routing_provider.dart';
import 'straight_line_provider.dart';

export 'routing_provider.dart' show RouteResult;

/// Routing service with cascade fallback:
///   1. TomTom Routing API   (requires TOMTOM_API_KEY in .env)
///   2. OSRM                 (public demo or OSRM_BASE_URL — no key required)
///   3. Straight-line        (always available, offline-safe)
///
/// All providers implement [RoutingProvider] and are tried in order until
/// one succeeds. The successful provider name is included in [RouteResult].
class RoutingService {
  RoutingService._();

  static final List<RoutingProvider> _providers = [
    TomTomRoutingProvider(),
    OsrmRoutingProvider(),
    const StraightLineProvider(),
  ];

  /// Get route from [origin] to [dest], trying providers in priority order.
  /// Always returns a result (straight-line is the final fallback).
  static Future<RouteResult> getRoute(LatLng origin, LatLng dest) async {
    for (final provider in _providers) {
      if (!provider.isAvailable) continue;
      final result = await provider.getRoute(origin, dest);
      if (result != null) {
        debugPrint('[Routing] Used ${result.providerName}');
        return result;
      }
    }
    // Straight-line is always isAvailable=true, so this should never be reached.
    return RouteResult(
      points:         [origin, dest],
      travelTimeSec:  0,
      distanceMeters: 0,
      providerName:   'none',
    );
  }
}
