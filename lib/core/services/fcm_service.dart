import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';

/// Handles FCM token registration and refresh.
/// Call [registerToken] once after every successful login/session restore.
/// Call [listenForRefresh] once at app startup so token rotations are forwarded.
class FcmService {
  FcmService._();

  /// Gets the current FCM token and registers it with the backend.
  /// Silent — never throws.
  static Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await ApiClient.put('/api/profile/fcm-token', {'fcmToken': token});
    } catch (_) {}
  }

  /// Subscribes to FCM token refresh events for the lifetime of the app.
  /// Call once from main() after Firebase is initialised.
  static void listenForRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await ApiClient.put('/api/profile/fcm-token', {'fcmToken': token});
      } catch (_) {}
    });
  }
}
