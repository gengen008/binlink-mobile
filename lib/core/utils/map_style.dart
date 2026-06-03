// Carto Voyager tile layer — free, no API key, clean light map visible on all networks
// Switched from dark_all (rendered pitch-black on Ghana networks) to voyager_labels_under
// which loads reliably and shows streets/landmarks clearly.
const String kMapTileUrl =
    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

const List<String> kMapTileSubdomains = ['a', 'b', 'c', 'd'];
