import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'http://10.0.2.2:3000';

  static String get tomtomApiKey =>
      dotenv.env['TOMTOM_API_KEY'] ?? '';

  static String get smartmapsApiKey =>
      dotenv.env['SMARTMAPS_API_KEY'] ?? '';

  /// OSRM self-hosted instance URL. Defaults to the public demo server.
  /// Set OSRM_BASE_URL in .env to override (recommended for production).
  static String get osrmBaseUrl =>
      dotenv.env['OSRM_BASE_URL'] ?? 'http://router.project-osrm.org';
}
