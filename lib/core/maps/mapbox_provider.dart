import 'package:dio/dio.dart';
import '../config/env.dart';
import 'map_provider.dart';

/// Mapbox raster tile provider — used as fallback when Carto is unavailable.
///
/// Requires MAPBOX_TOKEN in .env. Uses Mapbox Streets v12 style by default.
/// Tile URL: https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=TOKEN
class MapboxProvider implements MapTileProvider {
  const MapboxProvider();

  static String get _token => Env.mapboxToken;

  @override
  String get name => 'Mapbox Streets';

  @override
  bool get requiresApiKey => true;

  @override
  String get tileUrl {
    final token = _token;
    if (token.isEmpty) return '';
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}'
        '?access_token=$token';
  }

  @override
  List<String> get subdomains => const [];

  @override
  String get attribution =>
      '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>';

  @override
  Future<bool> healthCheck() async {
    if (_token.isEmpty) return false;
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final resp = await dio.get(
        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/5/15/12'
        '?access_token=$_token',
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
