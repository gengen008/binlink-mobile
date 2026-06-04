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
  runZonedGuarded(_appMain, _handleError);
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig.flavor = AppFlavor.household;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    FcmService.listenForRefresh();
  } catch (_) {
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

void _handleError(Object error, StackTrace stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
}
