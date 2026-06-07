import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Route result returned by any routing provider.
class RouteResult {
  final List<LatLng> points;
  final int travelTimeSec;
  final int distanceMeters;
  final String providerName;

  const RouteResult({
    required this.points,
    required this.travelTimeSec,
    required this.distanceMeters,
    required this.providerName,
  });

  int get travelTimeMin => (travelTimeSec / 60).ceil();
  double get distanceKm => distanceMeters / 1000.0;

  String get etaLabel {
    if (travelTimeMin < 1) return '< 1 min';
    if (travelTimeMin < 60) return '$travelTimeMin min';
    final h = travelTimeMin ~/ 60;
    final m = travelTimeMin % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

/// Abstract routing provider interface.
abstract class RoutingProvider {
  String get name;

  /// Whether this provider can be used right now (e.g. API key available).
  bool get isAvailable;

  /// Calculate the driving route from [origin] to [dest].
  /// Returns null if routing fails — caller should try next provider.
  Future<RouteResult?> getRoute(LatLng origin, LatLng dest);
}
