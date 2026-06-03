import 'package:dio/dio.dart';
import 'map_provider.dart';

/// Carto Voyager raster tiles — free, no API key, loads reliably on
/// low-bandwidth Ghana 3G networks.
///
/// Tile URL: https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png
class CartoProvider implements MapTileProvider {
  const CartoProvider();

  @override
  String get name => 'Carto Voyager';

  @override
  bool get requiresApiKey => false;

  @override
  String get tileUrl =>
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  @override
  List<String> get subdomains => const ['a', 'b', 'c', 'd'];

  @override
  String get attribution =>
      '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors © <a href="https://carto.com/attributions">CARTO</a>';

  @override
  Future<bool> healthCheck() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      // Probe a known tile at zoom 5 — small, fast download
      final resp = await dio.get(
        'https://a.basemaps.cartocdn.com/rastertiles/voyager/5/15/12.png',
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
