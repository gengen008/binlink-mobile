import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

const _kMoveDuration  = 1200.0; // ms — position lerp duration
const _kPulsePeriod   = 2200.0; // ms — one full pulse ring cycle

/// Manages animated collector markers + pulse rings on the household home map.
///
/// Two GeoJSON sources are created when [init] is called:
///   • `bl-pulse`      — expanding ripple rings (circle layer)
///   • `bl-collectors` — directional truck icons (symbol layer, bearing-driven)
///
/// A 33 ms timer (≈30 fps) drives all animations. Positions are lerped over
/// [_kMoveDuration] ms with ease-in-out; pulse rings cycle every [_kPulsePeriod] ms.
class CollectorLayer {
  CollectorLayer(this._ctrl);

  final MapLibreMapController _ctrl;
  final Map<String, _CollAnim> _anims = {};
  Timer? _ticker;
  bool _ready = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    final bytes = await _buildIcon();
    await _ctrl.addImage('bl-collector', bytes);
    await _ctrl.addGeoJsonSource('bl-pulse',      _emptyFc());
    await _ctrl.addGeoJsonSource('bl-collectors', _emptyFc());

    // Pulse ring circles (below truck icons)
    await _ctrl.addCircleLayer(
      'bl-pulse',
      'bl-pulse-layer',
      const CircleLayerProperties(
        circleRadius:  [Expressions.get, 'r'],
        circleOpacity: [Expressions.get, 'a'],
        circleColor:   '#22C55E',
        circleStrokeWidth: 0,
      ),
    );

    // Truck icon symbols with bearing rotation
    await _ctrl.addSymbolLayer(
      'bl-collectors',
      'bl-collector-layer',
      const SymbolLayerProperties(
        iconImage:             'bl-collector',
        iconSize:              0.65,
        iconAllowOverlap:      true,
        iconIgnorePlacement:   true,
        iconRotationAlignment: 'map',
        iconRotate:            [Expressions.get, 'bearing'],
      ),
    );

    _ready = true;
    _ticker = Timer.periodic(const Duration(milliseconds: 33), _tick);
  }

  /// Seed positions from the initial HTTP load.
  /// Safe to call multiple times — only adds collectors not yet tracked.
  void setInitial(List<Map<String, dynamic>> collectors) {
    final ids = <String>{};
    for (final c in collectors) {
      final id  = c['id']      as String?;
      final lat = (c['lastLat'] as num?)?.toDouble();
      final lng = (c['lastLng'] as num?)?.toDouble();
      if (id == null || id.isEmpty || lat == null || lng == null) continue;
      ids.add(id);
      _anims.putIfAbsent(id, () => _CollAnim(LatLng(lat, lng)));
    }
    _anims.removeWhere((id, _) => !ids.contains(id));
    _flushSources();
  }

  /// Smoothly animate a collector to a new GPS position.
  void updatePosition(String id, double lat, double lng, double bearing) {
    _anims.putIfAbsent(id, () => _CollAnim(LatLng(lat, lng)));
    _anims[id]!.moveTo(LatLng(lat, lng), bearing);
  }

  /// Remove a collector who went offline.
  void removeCollector(String id) {
    if (_anims.remove(id) != null) _flushSources();
  }

  void dispose() {
    _ticker?.cancel();
    _anims.clear();
  }

  // ── Animation tick ────────────────────────────────────────────────────────

  void _tick(Timer _) {
    if (!_ready) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final a in _anims.values) {
      a.tick(nowMs);
    }
    _flushSources();
  }

  void _flushSources() {
    if (!_ready) return;

    final markers = <Map<String, dynamic>>[];
    final rings   = <Map<String, dynamic>>[];

    for (final e in _anims.entries) {
      final a = e.value;

      markers.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [a.current.longitude, a.current.latitude],
        },
        'properties': {'id': e.key, 'bearing': a.bearing},
      });

      // Three staggered expanding rings
      for (var i = 0; i < 3; i++) {
        final phase = (a.pulsePhase + i * 0.333) % 1.0;
        final r     = 10.0 + phase * 26.0;
        final alpha = 0.40 * (1.0 - phase);
        if (alpha > 0.01) {
          rings.add({
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [a.current.longitude, a.current.latitude],
            },
            'properties': {'r': r, 'a': alpha},
          });
        }
      }
    }

    _ctrl.setGeoJsonSource(
        'bl-collectors', {'type': 'FeatureCollection', 'features': markers});
    _ctrl.setGeoJsonSource(
        'bl-pulse', {'type': 'FeatureCollection', 'features': rings});
  }

  // ── Icon builder ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _emptyFc() =>
      {'type': 'FeatureCollection', 'features': <dynamic>[]};

  static Future<Uint8List> _buildIcon() async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    canvas.drawCircle(
      const Offset(size / 2, size / 2), size / 2 - 1,
      Paint()
        ..color      = const Color(0x2016A34A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2), size / 2 - 5,
      Paint()..color = const Color(0xFF16A34A),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2), size / 2 - 5,
      Paint()
        ..color       = Colors.white
        ..strokeWidth = 2.5
        ..style       = ui.PaintingStyle.stroke,
    );
    // Arrow pointing up — MapLibre rotates it to the collector's bearing
    final path = Path()
      ..moveTo(size / 2,     10)
      ..lineTo(size / 2 - 9, size - 14)
      ..lineTo(size / 2,     size - 20)
      ..lineTo(size / 2 + 9, size - 14)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    final pic  = recorder.endRecording();
    final img  = await pic.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}

// ── Per-collector animation state ─────────────────────────────────────────────

class _CollAnim {
  _CollAnim(LatLng initial)
      : _from   = initial,
        _to     = initial,
        current = initial,
        _lastMs = DateTime.now().millisecondsSinceEpoch;

  LatLng _from;
  LatLng _to;
  LatLng current;
  double bearing    = 0;
  int    _moveStart = 0;
  int    _lastMs;
  double pulsePhase = 0;

  void moveTo(LatLng target, double bear) {
    bearing    = bear;
    _from      = current;
    _to        = target;
    _moveStart = DateTime.now().millisecondsSinceEpoch;
  }

  void tick(int nowMs) {
    final dt = (nowMs - _lastMs).clamp(1, 200);
    _lastMs = nowMs;

    // Smooth position lerp
    if (_moveStart > 0) {
      final t    = ((nowMs - _moveStart) / _kMoveDuration).clamp(0.0, 1.0);
      final ease = _easeInOut(t);
      current = LatLng(
        _from.latitude  + (_to.latitude  - _from.latitude)  * ease,
        _from.longitude + (_to.longitude - _from.longitude) * ease,
      );
      if (t >= 1.0) _moveStart = 0;
    }

    // Advance pulse phase
    pulsePhase = (pulsePhase + dt / _kPulsePeriod) % 1.0;
  }

  static double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}
