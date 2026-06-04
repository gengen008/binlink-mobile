import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/app_flavor.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

void main() {
  // runZonedGuarded ensures async errors outside the Flutter tree are also
  // captured (e.g. futures that throw after runApp returns).
  runZonedGuarded(_main, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.flavor = AppFlavor.household;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — Env class falls back to hardcoded defaults
  }

  try {
    await Firebase.initializeApp();

    // Route Flutter framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Ensure crash reporting is enabled in production
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Request notification permission (Android 13+, iOS) and start FCM token refresh listener
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    FcmService.listenForRefresh();
  } catch (_) {
    // Firebase not configured — fall back to default error presentation
    FlutterError.onError = FlutterError.presentError;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF021024),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const BinLinkApp());
}
