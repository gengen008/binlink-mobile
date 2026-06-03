// Dark Google Maps style — Uber/Bolt inspired
// Roads are clearly visible against the dark background
const String kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#12263a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ab4d9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1c3a56"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9ca3af"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e4a78"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0f2744"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7cb4d4"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#245d8f"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2f7ab5"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1a4f7a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#c1e8ff"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#183f63"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#071929"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4a7fa8"}]}
]
''';
