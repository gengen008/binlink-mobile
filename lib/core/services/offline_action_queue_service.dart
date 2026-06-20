import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/socket_service.dart';

class OfflineActionQueueService {
  OfflineActionQueueService._();

  static const _storageKey = 'offline_action_queue_v1';
  static Timer? _syncTimer;
  static StreamSubscription<SocketHealth>? _healthSub;
  static Future<Response<dynamic>> Function(
    String method,
    String path,
    dynamic data,
    Map<String, dynamic> headers,
  )? _dispatcher;
  static bool _syncing = false;

  static Future<void> init({
    required Future<Response<dynamic>> Function(
      String method,
      String path,
      dynamic data,
      Map<String, dynamic> headers,
    ) dispatcher,
  }) async {
    _dispatcher ??= dispatcher;
    _healthSub ??= SocketService.healthStream.listen((health) {
      if (health == SocketHealth.connected) {
        syncNow();
      }
    });
    _syncTimer ??=
        Timer.periodic(const Duration(seconds: 45), (_) => syncNow());
  }

  static bool shouldQueue(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = options.path;
    if (options.extra['skipOfflineQueue'] == true) return false;
    if (method == 'PUT' &&
        RegExp(r'^/api/bookings/[^/]+/(on-the-way|collecting|collected|arrived|complete|en-route)$')
            .hasMatch(path)) {
      return true;
    }
    if (method == 'POST' &&
        RegExp(r'^/api/bookings/[^/]+/(review|rating)$').hasMatch(path)) {
      return true;
    }
    if (method == 'POST' && path == '/api/support/tickets') {
      return true;
    }
    return false;
  }

  static Future<void> enqueue(RequestOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readQueue(prefs);
    final headers = <String, dynamic>{};
    final idempotencyKey = options.headers['Idempotency-Key'];
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    final item = <String, dynamic>{
      'id': _buildQueueId(options),
      'method': options.method.toUpperCase(),
      'path': options.path,
      'data': options.data,
      'headers': headers,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final existingIndex =
        items.indexWhere((queued) => queued['id'] == item['id']);
    if (existingIndex >= 0) {
      items[existingIndex] = item;
    } else {
      items.add(item);
    }
    await prefs.setString(_storageKey, jsonEncode(items));
  }

  static Future<void> syncNow() async {
    if (_syncing || _dispatcher == null) return;
    _syncing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await _readQueue(prefs);
      if (items.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final item in items) {
        try {
          await _dispatcher!(
            item['method'] as String? ?? 'POST',
            item['path'] as String? ?? '/',
            item['data'],
            Map<String, dynamic>.from(item['headers'] as Map? ?? const {}),
          );
        } on DioException catch (err) {
          final code = err.response?.statusCode ?? 0;
          final shouldDrop =
              code >= 400 && code < 500 && code != 408 && code != 429;
          if (!shouldDrop) {
            remaining.add(item);
          }
        } catch (_) {
          remaining.add(item);
        }
      }

      await prefs.setString(_storageKey, jsonEncode(remaining));
    } finally {
      _syncing = false;
    }
  }

  static Future<List<Map<String, dynamic>>> _readQueue(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _buildQueueId(RequestOptions options) {
    final base = jsonEncode(<String, dynamic>{
      'method': options.method.toUpperCase(),
      'path': options.path,
      'data': options.data,
      'idempotencyKey': options.headers['Idempotency-Key'],
    });
    return base.hashCode.toUnsigned(32).toRadixString(16);
  }
}
