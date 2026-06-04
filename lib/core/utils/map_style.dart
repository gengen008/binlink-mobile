import '../config/env.dart';

/// MapLibre GL style URL used as `styleString` in every MaplibreMap widget.
///
/// Priority:
///   1. SmartMaps dark style  — when SMARTMAPS_API_KEY is set in .env
///   2. OpenFreeMap dark      — free, no key, OSM-based fallback
String get kMapStyleUrl {
  final key = Env.smartmapsApiKey;
  if (key.isNotEmpty) {
    final encoded = Uri.encodeComponent(key);
    return 'https://tiles.smartmaps.cloud/styles/v1/smartmaps/dark/style.json?apiKey=$encoded';
  }
  return 'https://tiles.openfreemap.org/styles/dark';
}
