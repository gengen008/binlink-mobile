import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../config/env.dart';
import '../storage/secure_storage.dart';

/// Connection health state exposed to the app.
enum SocketHealth { connected, reconnecting, disconnected }

class SocketService {
  SocketService._();

  static sio.Socket? _socket;
  static Timer? _heartbeatTimer;

  // ── Re-join state ──────────────────────────────────────────────────────────
  // Server-side rooms die with the connection. Remember what we joined so a
  // reconnect transparently restores the zone feed, booking rooms and
  // collector online status.
  static double? _zoneLat;
  static double? _zoneLng;
  static final Set<String> _bookingRooms = {};
  static bool _collectorOnline = false;

  // ── Health stream ─────────────────────────────────────────────────────────
  static final _healthController = StreamController<SocketHealth>.broadcast();

  /// Stream of connection health events.
  /// Listen in UI widgets to show "Reconnecting…" banners.
  static Stream<SocketHealth> get healthStream => _healthController.stream;

  static SocketHealth _health = SocketHealth.disconnected;
  static SocketHealth get health => _health;

  static bool get isConnected => _socket?.connected ?? false;

  // ── Connect ───────────────────────────────────────────────────────────────
  static Future<void> connect() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null) return;

      _socket?.disconnect();

      _socket = sio.io(
        Env.socketUrl,
        sio.OptionBuilder()
            .setTransports([
              'websocket',
              'polling'
            ]) // polling fallback for firewalled networks
            .enableAutoConnect()
            .enableReconnection()
            // No attempt cap — a backend restart must never permanently kill
            // the live feed; delay backs off to 30s max.
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(30000) // cap at 30s
            .setAuth({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {
        _emitHealth(SocketHealth.connected);
        debugPrint('[Socket] Connected');
        _restoreRooms();
      });

      _socket!.on('reconnecting', (_) {
        _emitHealth(SocketHealth.reconnecting);
        debugPrint('[Socket] Reconnecting…');
      });

      _socket!.onDisconnect((_) {
        _emitHealth(SocketHealth.reconnecting);
        debugPrint('[Socket] Disconnected — will attempt reconnect');
      });

      _socket!.onError((err) {
        debugPrint('[Socket] Error: $err');
        FirebaseCrashlytics.instance
            .recordError(err, StackTrace.current,
                reason: 'Socket runtime error')
            .catchError((_) {});
      });

      _socket!.onConnectError((err) {
        _emitHealth(SocketHealth.reconnecting);
        debugPrint('[Socket] Connect error: $err');
        FirebaseCrashlytics.instance
            .recordError(err, StackTrace.current,
                reason: 'Socket connect error')
            .catchError((_) {});
      });
    } catch (e) {
      debugPrint('[Socket] connect() exception: $e');
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  static void disconnect() {
    _stopHeartbeat();
    _zoneLat = null;
    _zoneLng = null;
    _bookingRooms.clear();
    _collectorOnline = false;
    try {
      _socket?.disconnect();
    } catch (_) {}
    _socket = null;
    _emitHealth(SocketHealth.disconnected);
  }

  // ── Emit with optional acknowledgement callback ───────────────────────────
  /// Emit [event] with [data]. If [ack] is provided, server response is
  /// delivered to it (requires server to call the ack callback).
  static void emit(String event, [dynamic data, Function(dynamic)? ack]) {
    try {
      if (ack != null) {
        _socket?.emitWithAck(event, data, ack: (response) => ack(response));
      } else {
        _socket?.emit(event, data);
      }
    } catch (_) {}
  }

  static void on(String event, Function(dynamic) handler) {
    try {
      _socket?.on(event, handler);
    } catch (_) {}
  }

  static void off(String event) {
    try {
      _socket?.off(event);
    } catch (_) {}
  }

  static void offHandler(String event, void Function(dynamic) handler) {
    try {
      _socket?.off(event, handler);
    } catch (_) {}
  }

  // ── Booking room ──────────────────────────────────────────────────────────
  static void joinBookingRoom(String bookingId, [Function(dynamic)? ack]) {
    _bookingRooms.add(bookingId);
    emit('booking:join', {'bookingId': bookingId}, ack);
  }

  static void leaveBookingRoom(String bookingId) {
    _bookingRooms.remove(bookingId);
  }

  // ── Zone subscription — household subscribes to nearby collector feed ──────
  static void joinZone(double lat, double lng) {
    _zoneLat = lat;
    _zoneLng = lng;
    emit('zone:join', {'lat': lat, 'lng': lng});
  }

  static void leaveZone() {
    _zoneLat = null;
    _zoneLng = null;
    emit('zone:leave', null);
  }

  // ── Collector controls ────────────────────────────────────────────────────
  static void goOnline([Function(dynamic)? ack]) {
    _collectorOnline = true;
    emit('collector:go-online', null, ack);
    _startHeartbeat();
  }

  static void goOffline([Function(dynamic)? ack]) {
    _collectorOnline = false;
    _stopHeartbeat();
    emit('collector:go-offline', null, ack);
  }

  /// Re-establish server-side rooms after a (re)connect.
  static void _restoreRooms() {
    if (_zoneLat != null && _zoneLng != null) {
      emit('zone:join', {'lat': _zoneLat, 'lng': _zoneLng});
    }
    for (final id in _bookingRooms) {
      emit('booking:join', {'bookingId': id});
    }
    if (_collectorOnline) {
      emit('collector:go-online');
    }
  }

  /// Broadcast collector GPS position. Debounced on server side (10m min move).
  static void broadcastLocation(
      {String? bookingId, required double lat, required double lng}) {
    emit('collector:location', {
      if (bookingId != null) 'bookingId': bookingId,
      'lat': lat,
      'lng': lng,
    });
  }

  // ── Heartbeat ─────────────────────────────────────────────────────────────
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_socket?.connected == true) {
        _socket!.emit('collector:heartbeat', {});
      }
    });
  }

  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  static void _emitHealth(SocketHealth h) {
    _health = h;
    if (!_healthController.isClosed) {
      _healthController.add(h);
    }
  }
}
