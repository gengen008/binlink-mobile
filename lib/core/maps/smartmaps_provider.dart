import 'package:dio/dio.dart';
import '../config/env.dart';
import 'map_provider.dart';

/// SmartMaps (YellowMap) raster tiles proxied through the BinLink backend.
/// The API key lives on Railway — never exposed to the APK.
///
/// Tile URL: {API_BASE_URL}/api/tiles/{z}/{x}/{y}
class SmartMapsProvider implements MapTileProvider {
  const SmartMapsProvider();

  @override
  String get name => 'SmartMaps';

  @override
  bool get requiresApiKey => false; // key is on the server, not the client

  @override
  String get tileUrl => '${Env.apiBaseUrl}/api/tiles/{z}/{x}/{y}';

  @override
  List<String> get subdomains => const [];

  @override
  String get attribution =>
      '© <a href="https://www.smartmaps.net">SmartMaps</a> '
      '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>';

  @override
  Future<bool> healthCheck() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ));
      // Probe zoom-5 tile over Accra — fast sanity check
      final resp = await dio.get('${Env.apiBaseUrl}/api/tiles/5/15/12');
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
