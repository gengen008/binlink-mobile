import '../maps/map_service.dart';

/// Active tile URL from the running MapService provider.
/// All map screens use these getters — changing the active provider here
/// automatically propagates to every TileLayer in the app.
String get kMapTileUrl => MapService.instance.tileUrl;
List<String> get kMapTileSubdomains => MapService.instance.subdomains;
