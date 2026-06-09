import 'dart:math';

/// One-dimensional Kalman filter for GPS coordinate smoothing.
///
/// Each coordinate (lat, lng) runs through its own independent filter instance.
/// On Ghana 3G, GPS coordinates can jump 50–200m between readings — this filter
/// reduces that noise while preserving genuine movement direction.
///
/// Usage:
///   final latFilter = KalmanFilter1D();
///   final lngFilter = KalmanFilter1D();
///
///   // On each new GPS reading:
///   final smoothLat = latFilter.update(rawLat, accuracyMeters);
///   final smoothLng = lngFilter.update(rawLng, accuracyMeters);
class KalmanFilter1D {
  /// Process noise variance — higher = tracks real movement more aggressively.
  /// Tuned for vehicle movement at ~30 km/h urban speed.
  final double processNoise;

  /// Estimated position (the filtered output).
  double _estimate;

  /// Estimation error variance.
  double _errorCovariance;

  bool _initialized = false;

  KalmanFilter1D({this.processNoise = 1e-4})
      : _estimate = 0.0,
        _errorCovariance = 1.0;

  /// Update the filter with a new raw measurement.
  ///
  /// [measurement] — raw GPS coordinate (lat or lng).
  /// [accuracy] — GPS horizontal accuracy in metres (from geolocator).
  ///   Lower accuracy (higher number) → we trust the measurement less.
  ///
  /// Returns the smoothed coordinate.
  double update(double measurement, {double accuracy = 20.0}) {
    // First reading — accept it directly
    if (!_initialized) {
      _estimate = measurement;
      _initialized = true;
      return _estimate;
    }

    // Convert GPS accuracy to measurement noise variance.
    // Accuracy is in metres; coordinates are in degrees.
    // 1 degree ≈ 111 km → 1 m ≈ 9e-6 degrees.
    const metersPerDegree = 111000.0;
    final measurementNoise = pow(accuracy / metersPerDegree, 2).toDouble();

    // Predict step: propagate error covariance forward
    _errorCovariance += processNoise;

    // Kalman gain: how much to trust the new measurement vs our prediction
    final gain = _errorCovariance / (_errorCovariance + measurementNoise);

    // Update step: blend prediction with measurement
    _estimate += gain * (measurement - _estimate);
    _errorCovariance *= (1.0 - gain);

    return _estimate;
  }

  /// Reset the filter (e.g. when a new booking starts or location jumps > threshold).
  void reset() {
    _initialized = false;
    _estimate = 0.0;
    _errorCovariance = 1.0;
  }
}

/// Speed validator — rejects GPS updates that imply physically impossible speeds.
///
/// On Ghana 3G, "teleporting" updates (5+ km jumps in 1 second) are common.
/// This validator drops them before they reach the Kalman filter.
class GpsSpeedValidator {
  /// Maximum plausible speed for a waste collection vehicle, km/h.
  /// Urban Ghana: 60 km/h; use 80 to include highway transit between zones.
  static const maxSpeedKmh = 80.0;

  double? _lastLat;
  double? _lastLng;
  DateTime? _lastTime;

  /// Returns true if the new position is physically reachable from the last one.
  /// Always returns true for the first point (no prior reference).
  bool isValid(double lat, double lng) {
    final now = DateTime.now();
    final prevLat = _lastLat;
    final prevLng = _lastLng;
    final prevTime = _lastTime;

    _lastLat = lat;
    _lastLng = lng;
    _lastTime = now;

    if (prevLat == null || prevTime == null) return true;

    final elapsedSec = now.difference(prevTime).inMilliseconds / 1000.0;
    if (elapsedSec <= 0) return true;

    final distKm = _haversineKm(prevLat, prevLng!, lat, lng);
    final speedKmh = (distKm / elapsedSec) * 3600;

    return speedKmh <= maxSpeedKmh;
  }

  void reset() {
    _lastLat = null;
    _lastLng = null;
    _lastTime = null;
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a.clamp(0.0, 1.0)), sqrt((1 - a).clamp(0.0, 1.0)));
  }
}

/// Combined GPS smoother: validates speed then applies Kalman filter.
///
///   final smoother = GpsSmoother();
///   final smooth = smoother.process(rawLat, rawLng, accuracy: 15);
///   if (smooth != null) updateTruckMarker(smooth.lat, smooth.lng);
class GpsSmoother {
  final _latFilter = KalmanFilter1D();
  final _lngFilter = KalmanFilter1D();
  final _validator  = GpsSpeedValidator();

  /// Process a raw GPS reading. Returns null if the reading fails the speed
  /// validation check (i.e. it's likely a network-glitch teleport).
  ({double lat, double lng})? process(
    double rawLat,
    double rawLng, {
    double accuracy = 20.0,
  }) {
    if (!_validator.isValid(rawLat, rawLng)) return null;
    return (
      lat: _latFilter.update(rawLat,  accuracy: accuracy),
      lng: _lngFilter.update(rawLng, accuracy: accuracy),
    );
  }

  /// Call when a new booking starts or the user goes offline.
  void reset() {
    _latFilter.reset();
    _lngFilter.reset();
    _validator.reset();
  }
}
