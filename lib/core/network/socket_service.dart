import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/env.dart';
import '../storage/secure_storage.dart';

class SocketService {
  SocketService._();

  static IO.Socket? _socket;

  static bool get isConnected => _socket?.connected ?? false;

  static Future<void> connect() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null) return;

      _socket?.disconnect();

      _socket = IO.io(
        Env.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setAuth({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {});
      _socket!.onDisconnect((_) {});
      _socket!.onError((_) {});
    } catch (_) {
      // Socket connection failure must not crash the app
    }
  }

  static void disconnect() {
    try {
      _socket?.disconnect();
    } catch (_) {}
    _socket = null;
  }

  static void emit(String event, [dynamic data]) {
    try {
      _socket?.emit(event, data);
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

  static void joinBookingRoom(String bookingId) {
    emit('booking:join', {'bookingId': bookingId});
  }

  static void goOnline()  => emit('collector:go-online');
  static void goOffline() => emit('collector:go-offline');

  static void broadcastLocation(String bookingId, double lat, double lng) {
    emit('collector:location', {'bookingId': bookingId, 'lat': lat, 'lng': lng});
  }
}
