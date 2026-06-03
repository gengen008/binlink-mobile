import 'package:dio/dio.dart';
import '../config/env.dart';

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });
}

class PlaceDetail {
  final String address;
  final double lat;
  final double lng;

  const PlaceDetail({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class PlacesService {
  PlacesService._();

  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://maps.googleapis.com/maps/api',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static String get _key => Env.mapsApiKey;

  /// Autocomplete suggestions for a query string.
  /// Pass [lat] and [lng] to bias results toward user's location (Ghana default).
  static Future<List<PlacePrediction>> autocomplete(
    String input, {
    double lat = 5.6037,
    double lng = -0.1870,
  }) async {
    if (input.trim().length < 2) return [];
    try {
      final resp = await _dio.get('/place/autocomplete/json', queryParameters: {
        'input': input,
        'key': _key,
        'location': '$lat,$lng',
        'radius': 50000,
        'components': 'country:gh',
        'language': 'en',
      });
      final predictions = (resp.data['predictions'] as List?) ?? [];
      return predictions.map((p) {
        final structured = p['structured_formatting'] as Map<String, dynamic>? ?? {};
        return PlacePrediction(
          placeId: p['place_id'] as String? ?? '',
          mainText: structured['main_text'] as String? ?? '',
          secondaryText: structured['secondary_text'] as String? ?? '',
          fullText: p['description'] as String? ?? '',
        );
      }).where((p) => p.placeId.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get lat/lng + formatted address for a place ID.
  static Future<PlaceDetail?> getDetail(String placeId) async {
    try {
      final resp = await _dio.get('/place/details/json', queryParameters: {
        'place_id': placeId,
        'key': _key,
        'fields': 'formatted_address,geometry',
      });
      final result = resp.data['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final location = result['geometry']?['location'] as Map<String, dynamic>?;
      if (location == null) return null;
      return PlaceDetail(
        address: result['formatted_address'] as String? ?? '',
        lat: (location['lat'] as num).toDouble(),
        lng: (location['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode lat/lng to address string.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final resp = await _dio.get('/geocode/json', queryParameters: {
        'latlng': '$lat,$lng',
        'key': _key,
        'language': 'en',
      });
      final results = (resp.data['results'] as List?) ?? [];
      if (results.isEmpty) return null;
      return results.first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }
}
