import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show MapLibreMap;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_flavor.dart';
import 'env.dart';
import '../services/fcm_service.dart';

class CoreInitializer {
  static Future<void> init(AppFlavor flavor) async {
    WidgetsFlutterBinding.ensureInitialized();
    FlavorConfig.flavor = flavor;

    // MapLibre default (virtual display) hosts the map in a SurfaceView,
    // which Flutter virtual displays do NOT support — covering the map with
    // a sheet or moving it offstage (IndexedStack tab switch) crashes the
    // process natively on many devices. Hybrid composition makes maplibre
    // 0.26.1 render via TextureView instead, which survives both.
    MapLibreMap.useHybridComposition = true;

    // 1. Load Environment Variables
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('[Core] .env load failed: $e. Falling back to defaults.');
    }

    // 2. Initialize Supabase (Critical for Chat/Photos)
    try {
      if (Env.supabaseUrl.isNotEmpty) {
        await Supabase.initialize(
          url: Env.supabaseUrl,
          publishableKey: Env.supabaseAnonKey,
        );
      }
    } catch (e) {
      debugPrint('[Core] Supabase init failed: $e');
    }

    // 3. Initialize Firebase & Crashlytics
    try {
      await Firebase.initializeApp();
      
      // Route Flutter framework errors to Crashlytics
      // recordFlutterError (non-fatal) — NOT recordFlutterFatalError which kills the app
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterError(details);
      };

      // Enable crash reporting
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // 4. Notifications & Messaging
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      FcmService.listenForRefresh();
      
    } catch (e) {
      debugPrint('[Core] Firebase init failed: $e');
      // Fallback: Ensure UI errors are still presented if Crashlytics fails
      FlutterError.onError = FlutterError.presentError;
    }

    // 5. System Config
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final isCollector = flavor == AppFlavor.collector;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isCollector ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isCollector ? const Color(0xFF0F172A) : Colors.white,
      systemNavigationBarIconBrightness: isCollector ? Brightness.light : Brightness.dark,
    ));
  }

  static void handleError(Object error, StackTrace stack) {
    debugPrint('[Fatal Error] $error\n$stack');
    try {
      // Only attempt Crashlytics if initialized
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      // If Crashlytics itself throws, we just print and let the app die
      debugPrint('[Fatal Error] Could not report to Crashlytics');
    }
  }
}
