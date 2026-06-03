import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'http://10.0.2.2:3000';

  static String get mapsApiKey =>
      dotenv.env['MAPS_API_KEY'] ?? '';

  static String get tomtomApiKey =>
      dotenv.env['TOMTOM_API_KEY'] ?? '';
}
