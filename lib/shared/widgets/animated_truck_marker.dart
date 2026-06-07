import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/theme/app_assets.dart';

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

class AnimatedTruckMarkerWidget extends StatefulWidget {
  const AnimatedTruckMarkerWidget({
    super.key,
    required this.position,
    required this.bearing,
    this.eta,
    required this.onTap,
  });

  final LatLng position;
  final double bearing;
  final int? eta;
  final VoidCallback? onTap;

  @override
  State<AnimatedTruckMarkerWidget> createState() => _AnimatedTruckMarkerWidgetState();
}

class _AnimatedTruckMarkerWidgetState extends State<AnimatedTruckMarkerWidget> with SingleTickerProviderStateMixin {
  late LatLng _oldPosition;
  late double _oldBearing;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _oldPosition = widget.position;
    _oldBearing = widget.bearing;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 1.5 second interpolation
    );
    _controller.forward(from: 1.0);
  }

  @override
  void didUpdateWidget(covariant AnimatedTruckMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _oldPosition = oldWidget.position;
      _oldBearing = oldWidget.bearing;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: We interpolate the bearing and position here.
    // However, flutter_map Markers are built by the layer.
    // To animate the marker's MAP POSITION smoothly, we need to provide a stream of Markers to flutter_map.
    // A better way is to pass the AnimatedTruckMarkerWidget as a State manager that yields the Marker to BinLinkMap.
    
    // Instead, since this widget is the CHILD of the Marker, it cannot change its lat/lng on the map canvas.
    // The animation must happen higher up.
    return const SizedBox();
  }
}
