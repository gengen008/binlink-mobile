import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/gps/kalman_filter.dart';

class HouseholdProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _onlineCollectors = [];
  Map<String, dynamic>? _activeBooking;
  bool _loading = false;
  String? _error;

  // Live collector GPS during tracking (Kalman-smoothed)
  double? _collectorLat;
  double? _collectorLng;
  final _gpsSmoother = GpsSmoother();

  List<Map<String, dynamic>> get bookings => _bookings;
  List<Map<String, dynamic>> get onlineCollectors => _onlineCollectors;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  bool get loading => _loading;
  String? get error => _error;
  double? get collectorLat => _collectorLat;
  double? get collectorLng => _collectorLng;

  List<Map<String, dynamic>> get completedBookings =>
      _bookings.where((b) => b['status'] == 'COMPLETED').toList();

  // All bookings (for history + subscriptions display)
  List<Map<String, dynamic>> get allBookings => List.unmodifiable(_bookings);

  Future<void> loadBookings() async {
    _setLoading(true);
    try {
      final res = await ApiClient.get('/api/bookings');
      _bookings = List<Map<String, dynamic>>.from(res.data['data'] as List);
      _activeBooking = _bookings.firstWhere(
        (b) => ['PENDING', 'SEARCHING', 'ASSIGNED', 'ACCEPTED',
                 'EN_ROUTE', 'ON_THE_WAY', 'ARRIVED',
                 'COLLECTING', 'COLLECTED'].contains(b['status']),
        orElse: () => {},
      );
      if (_activeBooking?.isEmpty == true) _activeBooking = null;
      _error = null;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Failed to load bookings';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOnlineCollectors() async {
    try {
      final res = await ApiClient.get('/api/collectors/online');
      _onlineCollectors = List<Map<String, dynamic>>.from(res.data['data'] as List);
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> createBooking({
    required String binSize,
    required int extraBags,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String paymentMethod,
    String? wasteCategory,
    String? timePreference,
    double? estimatedWeightKg,
    String? addressNotes,
    DateTime? scheduledDate,
    String? frequency,
  }) async {
    _setLoading(true);
    try {
      final res = await ApiClient.post('/api/bookings', {
        'binSize': binSize,
        'extraBags': extraBags,
        'pickupAddress': pickupAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'paymentMethod': paymentMethod,
        if (wasteCategory != null) 'wasteCategory': wasteCategory,
        if (timePreference != null) 'timePreference': timePreference,
        if (estimatedWeightKg != null) 'estimatedWeightKg': estimatedWeightKg,
        if (addressNotes != null && addressNotes.isNotEmpty) 'addressNotes': addressNotes,
        if (scheduledDate != null) 'scheduledDate': scheduledDate.toIso8601String(),
        if (frequency != null) 'frequency': frequency,
      });
      final booking = Map<String, dynamic>.from(res.data['data'] as Map);
      _bookings.insert(0, booking);
      _activeBooking = booking;
      _error = null;
      notifyListeners();
      return booking;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Failed to create booking';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await ApiClient.put('/api/bookings/$bookingId/cancel', {'reason': reason});
      await loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }

  void listenToBooking(String bookingId) {
    SocketService.joinBookingRoom(bookingId);

    SocketService.on('booking:accepted', (data) {
      _updateBookingStatus(bookingId, 'ACCEPTED');
      final collector = (data as Map<String, dynamic>)['collector'];
      if (_activeBooking != null && collector != null) {
        _activeBooking = {..._activeBooking!, 'collector': collector, 'status': 'ACCEPTED'};
        notifyListeners();
      }
    });

    SocketService.on('booking:status', (data) {
      final d = data as Map<String, dynamic>;
      if (d['bookingId'] == bookingId) {
        _updateBookingStatus(bookingId, d['status'] as String);
        if (_activeBooking != null) {
          _activeBooking = {..._activeBooking!, 'status': d['status']};
        }
        notifyListeners();
      }
    });

    SocketService.on('collector:location', (data) {
      final d = data as Map<String, dynamic>;
      final rawLat = (d['lat'] as num).toDouble();
      final rawLng = (d['lng'] as num).toDouble();
      // Apply Kalman filter — rejects teleport glitches, smooths Ghana 3G noise
      final smooth = _gpsSmoother.process(rawLat, rawLng);
      if (smooth != null) {
        _collectorLat = smooth.lat;
        _collectorLng = smooth.lng;
        notifyListeners();
      }
    });
  }

  void stopListening() {
    SocketService.off('booking:accepted');
    SocketService.off('booking:status');
    SocketService.off('collector:location');
    _collectorLat = null;
    _collectorLng = null;
    _gpsSmoother.reset();
  }

  // ── Saved Addresses ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _savedAddresses = [];

  List<Map<String, dynamic>> get savedAddresses => _savedAddresses;

  Future<void> loadSavedAddresses() async {
    try {
      final res = await ApiClient.get('/api/profile/addresses');
      _savedAddresses = List<Map<String, dynamic>>.from(
          res.data['data'] as List? ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addSavedAddress({
    required String label,
    required String address,
    double? lat,
    double? lng,
    String? gateNotes,
  }) async {
    try {
      final res = await ApiClient.post('/api/profile/addresses', {
        'label': label,
        'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (gateNotes != null && gateNotes.isNotEmpty) 'gateNotes': gateNotes,
      });
      final added = Map<String, dynamic>.from(res.data['data'] as Map);
      _savedAddresses.insert(0, added);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteSavedAddress(String id) async {
    _savedAddresses.removeWhere((a) => a['id'] == id);
    notifyListeners();
    try {
      await ApiClient.delete('/api/profile/addresses/$id');
    } catch (_) {
      await loadSavedAddresses();
    }
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _subscriptions = [];

  List<Map<String, dynamic>> get subscriptions => _subscriptions;

  Future<void> loadSubscriptions() async {
    try {
      final res = await ApiClient.get('/api/subscriptions/mine');
      _subscriptions = List<Map<String, dynamic>>.from(
          res.data['data'] as List? ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> createSubscription({
    required String plan,
    required String binSize,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    int? pickupDay,
    String? pickupTime,
    String? wasteType,
    String? addressNotes,
  }) async {
    try {
      final res = await ApiClient.post('/api/subscriptions', {
        'plan': plan,
        'binSize': binSize,
        'pickupAddress': pickupAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        if (pickupDay != null) 'pickupDay': pickupDay,
        if (pickupTime != null) 'pickupTime': pickupTime,
        if (wasteType != null && wasteType.isNotEmpty) 'wasteType': wasteType,
        if (addressNotes != null && addressNotes.isNotEmpty)
          'addressNotes': addressNotes,
      });
      final sub = Map<String, dynamic>.from(res.data['data'] as Map);
      _subscriptions.insert(0, sub);
      notifyListeners();
      return sub;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Failed to create subscription';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.patch('/api/subscriptions/$id', data);
      final updated = Map<String, dynamic>.from(res.data['data'] as Map);
      final idx = _subscriptions.indexWhere((s) => s['id'] == id);
      if (idx >= 0) _subscriptions[idx] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelSubscription(String id) async {
    try {
      await ApiClient.delete('/api/subscriptions/$id');
      final idx = _subscriptions.indexWhere((s) => s['id'] == id);
      if (idx >= 0) {
        _subscriptions[idx] = {..._subscriptions[idx], 'status': 'CANCELLED'};
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _updateBookingStatus(String bookingId, String status) {
    final idx = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (idx >= 0) {
      _bookings[idx] = {..._bookings[idx], 'status': status};
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // ── Test-only setters ───────────────────────────────────────────────────────
  @visibleForTesting
  set bookingsForTest(List<Map<String, dynamic>> bookings) {
    _bookings = bookings;
    _activeBooking = _bookings.where((b) => [
      'PENDING', 'SEARCHING', 'ASSIGNED', 'ACCEPTED',
      'EN_ROUTE', 'ON_THE_WAY', 'ARRIVED', 'COLLECTING', 'COLLECTED',
    ].contains(b['status'])).firstOrNull;
  }

  @visibleForTesting
  set subscriptionsForTest(List<Map<String, dynamic>> subs) {
    _subscriptions = subs;
  }
}
