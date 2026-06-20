import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../navigation/nav_service.dart';
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

  /// Shows an in-app banner when an FCM message arrives while the app is
  /// in the foreground. Android does not auto-display notification payloads
  /// when the app is open — this fills that gap without requiring a second
  /// notification package.
  static void listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? message.data['title'] as String? ?? '';
      final body = message.notification?.body ?? message.data['body'] as String? ?? '';
      if (title.isEmpty && body.isEmpty) return;

      final context = NavService.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (body.isNotEmpty)
                Text(body, style: const TextStyle(fontSize: 13)),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }
}
