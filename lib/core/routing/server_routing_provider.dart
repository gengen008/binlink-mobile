import 'package:latlong2/latlong.dart';
import '../config/env.dart';
import '../network/api_client.dart';
import 'routing_provider.dart';

/// Routes via BinLink backend /api/directions proxy.
///
/// The backend holds the Google Maps API key server-side — no key exposure.
/// Falls back gracefully when the backend is unreachable.
class ServerRoutingProvider implements RoutingProvider {
  const ServerRoutingProvider();

  @override
  String get name => 'BinLink Server (Google Directions)';

  @override
  bool get isAvailable => Env.apiBaseUrl.isNotEmpty;

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    try {
      final resp = await ApiClient.get('/api/directions', params: {
        'olat': origin.latitude.toString(),
        'olng': origin.longitude.toString(),
        'dlat': dest.latitude.toString(),
        'dlng': dest.longitude.toString(),
      });

      if (resp.data['success'] != true) return null;
      final data = resp.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      // Decode Google-encoded polyline string
      final encoded = data['points'] as String? ?? '';
      final points = _decodePolyline(encoded);

      final distance = data['distance'] as Map<String, dynamic>?;
      final duration = data['duration'] as Map<String, dynamic>?;

      return RouteResult(
        points:         points,
        travelTimeSec:  (duration?['value'] as num?)?.toInt() ?? 0,
        distanceMeters: (distance?['value'] as num?)?.toInt() ?? 0,
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

      shift = 0; result = 0;
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
