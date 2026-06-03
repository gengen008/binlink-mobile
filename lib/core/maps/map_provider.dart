/// Abstract interface for map tile providers.
/// Each provider supplies a tile URL template and optional subdomains
/// compatible with flutter_map's TileLayer.
abstract class MapTileProvider {
  /// Human-readable name (used in logs and debug overlays).
  String get name;

  /// Whether this provider requires an API key to work.
  bool get requiresApiKey;

  /// flutter_map urlTemplate — e.g. 'https://{s}.example.com/{z}/{x}/{y}.png'
  String get tileUrl;

  /// Subdomain list for {s} placeholder rotation. Empty if not used.
  List<String> get subdomains;

  /// Attribution text displayed on map (required by most tile providers).
  String get attribution;

  /// Perform a lightweight health check. Returns true if tiles are reachable.
  /// Implementations should time out within 5 seconds.
  Future<bool> healthCheck();
}
