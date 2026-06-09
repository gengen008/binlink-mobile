import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';

class CollectorProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _activePickups   = [];
  List<Map<String, dynamic>> _completedPickups = [];
  bool _isOnline = false;
  bool _loading = false;
  String? _error;

  StreamSubscription? _locationSub;
  bool _listeningForBookings = false;

  double? _currentLat;
  double? _currentLng;
  double? _currentHeading;
  double? _currentSpeedKph;

  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  double? get currentHeading => _currentHeading;
  double get currentSpeedKph => _currentSpeedKph ?? 0.0;

  List<Map<String, dynamic>> get pendingRequests  => _pendingRequests;
  List<Map<String, dynamic>> get activePickups    => _activePickups;
  List<Map<String, dynamic>> get completedPickups => _completedPickups;
  bool get isOnline  => _isOnline;
  bool get loading   => _loading;
  String? get error  => _error;

  Map<String, dynamic>? get currentActivePickup =>
      _activePickups.isNotEmpty ? _activePickups.first : null;

  // Earnings helpers
  // Platform takes 10%; collector earns 90% of totalAmount
  static const _collectorRate = 0.9;
  Map<String, dynamic>? _earningsSummary;

  double get totalEarnings => Fmt.toDouble(_earningsSummary?['lifetime']?['netEarnings']);

  double get todayEarnings => _completedPickups.where((b) {
    final d = DateTime.tryParse(b['completedAt'] as String? ?? '');
    return d != null &&
        d.day == DateTime.now().day &&
        d.month == DateTime.now().month &&
        d.year == DateTime.now().year;
  }).fold(0, (s, b) => s + Fmt.toDouble(b['totalAmount']) * _collectorRate);

  int get todayPickups => _completedPickups.where((b) {
    final d = DateTime.tryParse(b['completedAt'] as String? ?? '');
    return d != null &&
        d.day == DateTime.now().day &&
        d.month == DateTime.now().month &&
        d.year == DateTime.now().year;
  }).length;

  int get totalPickups => _completedPickups.length;

  Future<void> loadEarningsSummary() async {
    try {
      final res = await ApiClient.get('/api/collectors/earnings/summary');
      _earningsSummary = Map<String, dynamic>.from(res.data['data'] as Map);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadDashboard() async {
    _setLoading(true);
    try {
      // Load this collector's assigned/completed bookings
      final res = await ApiClient.get('/api/bookings');
      final all = List<Map<String, dynamic>>.from(res.data['data'] as List);
      _completedPickups = all.where((b) => b['status'] == 'COMPLETED').toList();
      _activePickups    = all.where((b) =>
        ['ASSIGNED', 'ACCEPTED', 'EN_ROUTE', 'ON_THE_WAY',
         'ARRIVED', 'COLLECTING', 'COLLECTED'].contains(b['status'])
      ).toList();

      // Load unassigned PENDING bookings within 30 km — fills the request queue
      // even when the collector was offline when jobs were created
      final avail = await ApiClient.get('/api/bookings/available');
      final available = List<Map<String, dynamic>>.from(avail.data['data'] as List? ?? []);
      // Merge: keep existing socket-received jobs, add any new ones from API
      for (final b in available) {
        if (!_pendingRequests.any((r) => r['id'] == b['id'])) {
          _pendingRequests.add(b);
        }
      }

      _error = null;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Failed to load dashboard';
    } finally {
      _setLoading(false);
    }
    loadEarningsSummary().catchError((_) {});
    _listenForNewBookings();
  }

  void _listenForNewBookings() {
    if (_listeningForBookings) return;
    _listeningForBookings = true;
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

    SocketService.on('booking:completed', (data) {
      final booking = Map<String, dynamic>.from(data as Map);
      _activePickups.removeWhere((p) => p['id'] == booking['id']);
      if (!_completedPickups.any((p) => p['id'] == booking['id'])) {
        _completedPickups.insert(0, booking);
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
      _error = e is DioException
          ? (e.response?.data?['error'] ?? 'Failed to go ${newState ? 'online' : 'offline'}')
          : 'Network error — check connection';
      notifyListeners();
    }
  }

  void _startLocationBroadcast() {
    _locationSub?.cancel();
    _locationSub = LocationService.getPositionStream().listen((pos) async {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _currentHeading = pos.heading;
      _currentSpeedKph = pos.speed * 3.6;
      notifyListeners();

      // Broadcast general location for zones (always)
      SocketService.broadcastLocation(
        lat: pos.latitude,
        lng: pos.longitude,
      );

      // Targeted broadcast to active booking rooms
      for (final pickup in _activePickups) {
        if (['EN_ROUTE', 'ON_THE_WAY', 'ARRIVED', 'COLLECTING'].contains(pickup['status'])) {
          SocketService.broadcastLocation(
            bookingId: pickup['id'] as String,
            lat: pos.latitude,
            lng: pos.longitude,
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

  Future<void> declineRequest(String bookingId) async {
    try {
      await ApiClient.post('/api/bookings/$bookingId/decline', {});
      _pendingRequests.removeWhere((r) => r['id'] == bookingId);
      notifyListeners();
    } catch (_) {
      // Still remove locally to clean up UI
      _pendingRequests.removeWhere((r) => r['id'] == bookingId);
      notifyListeners();
    }
  }

  Future<void> updateStatus(String bookingId, String action, {double? actualWeightKg}) async {
    try {
      final body = <String, dynamic>{};
      if (action == 'complete' && actualWeightKg != null) {
        body['actualWeightKg'] = actualWeightKg;
      }
      await ApiClient.put('/api/bookings/$bookingId/$action', body.isEmpty ? null : body);
      final statusMap = {
        'on-the-way': 'ON_THE_WAY',
        'collecting': 'COLLECTING',
        'collected':  'COLLECTED',
        // Legacy aliases kept for backward compat
        'en-route':   'EN_ROUTE',
        'arrived':    'ARRIVED',
        'complete':   'COMPLETED',
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
      _allJobs.where((b) => ['ASSIGNED', 'ACCEPTED', 'EN_ROUTE', 'ON_THE_WAY',
                              'ARRIVED', 'COLLECTING', 'COLLECTED'].contains(b['status'])).toList();
  List<Map<String, dynamic>> get pendingJobs =>
      _allJobs.where((b) => ['PENDING', 'SEARCHING', 'ASSIGNED']
          .contains(b['status'])).toList();
  List<Map<String, dynamic>> get completedJobs =>
      _allJobs.where((b) => b['status'] == 'COMPLETED').toList();
  bool get loadingJobs => _loadingJobs;

  Future<void> loadJobs() async {
    _loadingJobs = true;
    notifyListeners();
    try {
      // Assigned/completed bookings for this collector
      final res = await ApiClient.get('/api/bookings');
      final mine = List<Map<String, dynamic>>.from(res.data['data'] as List? ?? []);

      // Available PENDING bookings (unassigned, within 30 km)
      final avail = await ApiClient.get('/api/bookings/available');
      final available = List<Map<String, dynamic>>.from(avail.data['data'] as List? ?? []);

      // Merge: deduplicate by id
      final merged = <String, Map<String, dynamic>>{};
      for (final b in mine) {
        merged[b['id'] as String] = b;
      }
      for (final b in available) {
        merged.putIfAbsent(b['id'] as String, () => b);
      }
      _allJobs = merged.values.toList()
        ..sort((a, b) => (b['createdAt'] as String? ?? '').compareTo(a['createdAt'] as String? ?? ''));
    } catch (_) {}
    _loadingJobs = false;
    notifyListeners();
  }

  // ── Wallet / Payout ────────────────────────────────────────────────────────
  Map<String, dynamic>? _wallet;
  bool _loadingWallet = false;

  double get walletAvailable  => Fmt.toDouble(_wallet?['available']);
  double get walletPending    => Fmt.toDouble(_wallet?['pending']);
  double get walletWithdrawn  => Fmt.toDouble(_wallet?['totalWithdrawn']);
  List<Map<String, dynamic>> get walletTransactions =>
      List<Map<String, dynamic>>.from(_wallet?['transactions'] as List? ?? []);
  bool get loadingWallet => _loadingWallet;

  Future<void> loadWallet() async {
    _loadingWallet = true;
    notifyListeners();
    try {
      final res = await ApiClient.get('/api/collectors/wallet');
      _wallet = Map<String, dynamic>.from(res.data['data'] as Map);
    } catch (_) {}
    _loadingWallet = false;
    notifyListeners();
  }

  Future<bool> requestPayout(String momoNumber, double amount, String network) async {
    try {
      await ApiClient.post('/api/collectors/payout', {
        'momoNumber': momoNumber,
        'amount': amount,
        'network': network,
      });
      await loadWallet();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Payout request failed';
      notifyListeners();
      return false;
    }
  }

  // ── Exception / photo reporting ───────────────────────────────────────────
  Future<String?> uploadPhoto(String bookingId, String type, String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'type': type,
        'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final res = await ApiClient.upload('/api/bookings/$bookingId/photos', formData);
      return res.data['data']?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

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
    _listeningForBookings = false;
    super.dispose();
  }
}
