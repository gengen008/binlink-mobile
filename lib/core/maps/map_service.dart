import 'dart:async';
import 'package:flutter/foundation.dart';
import 'carto_provider.dart';
import 'map_provider.dart';
import 'mapbox_provider.dart';

/// Singleton map service.
///
/// Priority order:
///   1. Carto Voyager (free, no key, reliable on Ghana 3G)
///   2. Mapbox Streets  (fallback — needs MAPBOX_TOKEN)
///
/// Health monitoring:
///   - On init, probes the primary provider.
///   - If primary fails, switches to next provider that passes its health check.
///   - Re-probes every [_recheckInterval] (default 5 min) in case primary recovers.
///   - Exposes a [ChangeNotifier]-compatible stream so map widgets can rebuild
///     when the active provider changes.
class MapService extends ChangeNotifier {
  MapService._();
  static final MapService instance = MapService._();

  static const _recheckInterval = Duration(minutes: 5);

  static const List<MapTileProvider> _providers = [
    CartoProvider(),
    MapboxProvider(),
  ];

  MapTileProvider _active = _providers.first;
  Timer? _recheckTimer;
  bool _initialized = false;

  MapTileProvider get active => _active;

  /// Tile URL for the currently active provider.
  String get tileUrl => _active.tileUrl;

  /// Subdomain list for the currently active provider.
  List<String> get subdomains => _active.subdomains;

  /// Initialize: probe providers and pick the best available one.
  /// Safe to call multiple times — only runs once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _pickBestProvider();
    _recheckTimer = Timer.periodic(_recheckInterval, (_) => _recheckPrimary());
  }

  /// Try each provider in priority order, pick the first healthy one.
  Future<void> _pickBestProvider() async {
    for (final provider in _providers) {
      // Skip providers that require an API key but don't have one
      if (provider.requiresApiKey && provider.tileUrl.isEmpty) continue;
      final healthy = await provider.healthCheck();
      if (healthy) {
        _setActive(provider);
        return;
      }
    }
    // All failed — stay on current (Carto is the safest offline fallback)
    debugPrint('[MapService] All providers unhealthy — using ${_active.name}');
  }

  /// Periodically try to switch back to a higher-priority provider if it has recovered.
  Future<void> _recheckPrimary() async {
    for (final provider in _providers) {
      if (provider == _active) return; // already on best available
      if (provider.requiresApiKey && provider.tileUrl.isEmpty) continue;
      final healthy = await provider.healthCheck();
      if (healthy) {
        _setActive(provider);
        return;
      }
    }
  }

  void _setActive(MapTileProvider provider) {
    if (_active.name == provider.name) return;
    debugPrint('[MapService] Switching to ${provider.name}');
    _active = provider;
    notifyListeners();
  }

  @override
  void dispose() {
    _recheckTimer?.cancel();
    super.dispose();
  }
}
