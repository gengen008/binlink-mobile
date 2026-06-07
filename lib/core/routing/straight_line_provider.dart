import 'dart:math';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'routing_provider.dart';

/// Last-resort fallback: straight line between origin and destination.
/// Always available — no network, no API key required.
/// ETA estimated at 30 km/h average urban speed.
class StraightLineProvider implements RoutingProvider {
  const StraightLineProvider();

  static const _avgSpeedKmh = 30.0;

  @override
  String get name => 'Straight Line (fallback)';

  @override
  bool get isAvailable => true;

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    final distM = _haversineMeters(origin, dest);
    final travelSec = (distM / (_avgSpeedKmh * 1000 / 3600)).round();

    // 5 intermediate points for a smooth-ish line on the map
    const steps = 5;
    final points = List.generate(steps + 1, (i) {
      final t = i / steps;
      return LatLng(
        origin.latitude  + (dest.latitude  - origin.latitude)  * t,
        origin.longitude + (dest.longitude - origin.longitude) * t,
      );
    });

    return RouteResult(
      points:         points,
      travelTimeSec:  travelSec,
      distanceMeters: distM.round(),
      providerName:   name,
    );
  }

  static double _haversineMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude  - a.latitude)  * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final sinDlat = sin(dLat / 2);
    final sinDlng = sin(dLng / 2);
    final x = sinDlat * sinDlat +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sinDlng * sinDlng;
    return R * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}
