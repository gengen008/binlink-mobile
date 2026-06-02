import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';

class HouseholdProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _onlineCollectors = [];
  Map<String, dynamic>? _activeBooking;
  bool _loading = false;
  String? _error;

  // Live collector GPS during tracking
  double? _collectorLat;
  double? _collectorLng;

  List<Map<String, dynamic>> get bookings => _bookings;
  List<Map<String, dynamic>> get onlineCollectors => _onlineCollectors;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  bool get loading => _loading;
  String? get error => _error;
  double? get collectorLat => _collectorLat;
  double? get collectorLng => _collectorLng;

  List<Map<String, dynamic>> get completedBookings =>
      _bookings.where((b) => b['status'] == 'COMPLETED').toList();

  Future<void> loadBookings() async {
    _setLoading(true);
    try {
      final res = await ApiClient.get('/api/bookings');
      _bookings = List<Map<String, dynamic>>.from(res.data['data'] as List);
      _activeBooking = _bookings.firstWhere(
        (b) => ['PENDING', 'ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(b['status']),
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
    DateTime? scheduledDate,
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
        if (scheduledDate != null) 'scheduledDate': scheduledDate.toIso8601String(),
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
      _collectorLat = (d['lat'] as num).toDouble();
      _collectorLng = (d['lng'] as num).toDouble();
      notifyListeners();
    });
  }

  void stopListening() {
    SocketService.off('booking:accepted');
    SocketService.off('booking:status');
    SocketService.off('collector:location');
    _collectorLat = null;
    _collectorLng = null;
  }

  Future<bool> initiatePayment(String bookingId, String momoPhone) async {
    try {
      final res = await ApiClient.post('/api/payments/initiate', {
        'bookingId': bookingId,
        'momoPhone': momoPhone,
      });
      return res.data['success'] as bool? ?? false;
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
}
