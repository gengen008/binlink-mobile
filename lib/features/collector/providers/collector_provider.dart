import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/services/location_service.dart';

class CollectorProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _activePickups   = [];
  List<Map<String, dynamic>> _completedPickups = [];
  bool _isOnline = false;
  bool _loading = false;
  String? _error;

  StreamSubscription? _locationSub;

  List<Map<String, dynamic>> get pendingRequests  => _pendingRequests;
  List<Map<String, dynamic>> get activePickups    => _activePickups;
  List<Map<String, dynamic>> get completedPickups => _completedPickups;
  bool get isOnline  => _isOnline;
  bool get loading   => _loading;
  String? get error  => _error;

  Map<String, dynamic>? get currentActivePickup =>
      _activePickups.isNotEmpty ? _activePickups.first : null;

  // Earnings helpers
  double get todayEarnings => _completedPickups.where((b) {
    final d = DateTime.tryParse(b['completedAt'] as String? ?? '');
    return d != null &&
        d.day == DateTime.now().day &&
        d.month == DateTime.now().month &&
        d.year == DateTime.now().year;
  }).fold(0, (s, b) => s + ((b['totalAmount'] as num?)?.toDouble() ?? 0));

  int get todayPickups => _completedPickups.where((b) {
    final d = DateTime.tryParse(b['completedAt'] as String? ?? '');
    return d != null &&
        d.day == DateTime.now().day &&
        d.month == DateTime.now().month &&
        d.year == DateTime.now().year;
  }).length;

  int get totalPickups => _completedPickups.length;

  Future<void> loadDashboard() async {
    _setLoading(true);
    try {
      final res = await ApiClient.get('/api/bookings');
      final all = List<Map<String, dynamic>>.from(res.data['data'] as List);
      _completedPickups = all.where((b) => b['status'] == 'COMPLETED').toList();
      _activePickups    = all.where((b) =>
        ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(b['status'])
      ).toList();
      _error = null;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Failed to load dashboard';
    } finally {
      _setLoading(false);
    }
    _listenForNewBookings();
  }

  void _listenForNewBookings() {
    SocketService.on('booking:new', (data) {
      final booking = Map<String, dynamic>.from(data as Map);
      if (!_pendingRequests.any((r) => r['id'] == booking['id'])) {
        _pendingRequests.insert(0, booking);
        notifyListeners();
      }
    });

    SocketService.on('booking:taken', (data) {
      final id = (data as Map<String, dynamic>)['bookingId'] as String?;
      if (id != null) {
        _pendingRequests.removeWhere((r) => r['id'] == id);
        notifyListeners();
      }
    });
  }

  Future<void> toggleOnline() async {
    final newState = !_isOnline;
    _isOnline = newState;
    notifyListeners();

    try {
      await ApiClient.put('/api/profile/online', {'isOnline': newState});
      if (newState) {
        SocketService.goOnline();
        _startLocationBroadcast();
      } else {
        SocketService.goOffline();
        _stopLocationBroadcast();
        _pendingRequests.clear();
        notifyListeners();
      }
    } catch (e) {
      _isOnline = !newState;
      notifyListeners();
    }
  }

  void _startLocationBroadcast() {
    _locationSub?.cancel();
    _locationSub = LocationService.getPositionStream().listen((pos) async {
      try {
        await ApiClient.put('/api/profile/location', {
          'lat': pos.latitude, 'lng': pos.longitude,
        });
      } catch (_) {}

      // Broadcast to any active booking rooms
      for (final pickup in _activePickups) {
        if (pickup['status'] == 'EN_ROUTE') {
          SocketService.broadcastLocation(
            pickup['id'] as String,
            pos.latitude,
            pos.longitude,
          );
        }
      }
    });
  }

  void _stopLocationBroadcast() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  Future<bool> acceptRequest(String bookingId) async {
    try {
      final res = await ApiClient.put('/api/bookings/$bookingId/accept');
      final booking = Map<String, dynamic>.from(res.data['data'] as Map);
      _pendingRequests.removeWhere((r) => r['id'] == bookingId);
      _activePickups.add(booking);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Failed to accept booking';
      notifyListeners();
      return false;
    }
  }

  void declineRequest(String bookingId) {
    _pendingRequests.removeWhere((r) => r['id'] == bookingId);
    notifyListeners();
  }

  Future<void> updateStatus(String bookingId, String action) async {
    try {
      await ApiClient.put('/api/bookings/$bookingId/$action');
      final statusMap = {
        'en-route': 'EN_ROUTE',
        'arrived':  'ARRIVED',
        'complete': 'COMPLETED',
      };
      final newStatus = statusMap[action];
      final idx = _activePickups.indexWhere((p) => p['id'] == bookingId);
      if (idx >= 0 && newStatus != null) {
        if (newStatus == 'COMPLETED') {
          final pickup = {..._activePickups[idx], 'status': newStatus, 'completedAt': DateTime.now().toIso8601String()};
          _activePickups.removeAt(idx);
          _completedPickups.insert(0, pickup);
        } else {
          _activePickups[idx] = {..._activePickups[idx], 'status': newStatus};
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Jobs for PickupsScreen ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _allJobs  = [];
  bool _loadingJobs = false;

  List<Map<String, dynamic>> get assignedJobs =>
      _allJobs.where((b) => ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(b['status'])).toList();
  List<Map<String, dynamic>> get pendingJobs =>
      _allJobs.where((b) => b['status'] == 'PENDING').toList();
  List<Map<String, dynamic>> get completedJobs =>
      _allJobs.where((b) => b['status'] == 'COMPLETED').toList();
  bool get loadingJobs => _loadingJobs;

  Future<void> loadJobs() async {
    _loadingJobs = true;
    notifyListeners();
    try {
      final res = await ApiClient.get('/api/bookings');
      _allJobs = List<Map<String, dynamic>>.from(res.data['data'] as List? ?? []);
    } catch (_) {}
    _loadingJobs = false;
    notifyListeners();
  }

  // ── Wallet / Payout ────────────────────────────────────────────────────────
  Map<String, dynamic>? _wallet;
  bool _loadingWallet = false;

  double get walletAvailable    => (_wallet?['available']     as num?)?.toDouble() ?? 0;
  double get walletPending      => (_wallet?['pending']       as num?)?.toDouble() ?? 0;
  double get walletWithdrawn    => (_wallet?['totalWithdrawn'] as num?)?.toDouble() ?? 0;
  List<Map<String, dynamic>> get walletTransactions =>
      List<Map<String, dynamic>>.from(_wallet?['transactions'] as List? ?? []);
  bool get loadingWallet => _loadingWallet;

  Future<void> loadWallet() async {
    _loadingWallet = true;
    notifyListeners();
    try {
      final res = await ApiClient.get('/api/collector/wallet');
      _wallet = Map<String, dynamic>.from(res.data['data'] as Map);
    } catch (_) {}
    _loadingWallet = false;
    notifyListeners();
  }

  Future<bool> requestPayout(String momoNumber, double amount) async {
    try {
      await ApiClient.post('/api/collector/payout', {
        'momoNumber': momoNumber,
        'amount': amount,
      });
      await loadWallet();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Payout request failed';
      notifyListeners();
      return false;
    }
  }

  // ── Exception / photo reporting stubs ──────────────────────────────────────
  Future<void> reportException(
      String bookingId, String reason, String? note) async {
    try {
      await ApiClient.patch('/api/bookings/$bookingId/exception', {
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } catch (_) {}
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    SocketService.off('booking:new');
    SocketService.off('booking:taken');
    super.dispose();
  }
}
