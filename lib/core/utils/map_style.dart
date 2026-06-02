// Dark Google Maps style matching BinLink color palette
// #021024 navy bg, #052659 roads, #7da0ca labels, #0a1929 water
const String kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#021024"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#7da0ca"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#021024"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a3a5c"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#052659"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#021024"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7da0ca"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1a3a5c"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#c1e8ff"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a1929"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5483b3"}]}
]
''';
