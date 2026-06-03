import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_flavor.dart';
import 'core/maps/map_service.dart';
import 'app.dart';

void main() {
  runZonedGuarded(_appMain, _handleError);
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  FlavorConfig.flavor = AppFlavor.household;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env failed to load — app will use fallback URLs from Env class
  }

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not yet configured — auth will handle gracefully
  }

  // Probe map tile providers in background — app starts with Carto default
  // and switches if a higher-priority provider becomes available
  MapService.instance.init(); // intentionally not awaited

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
  // Silently swallow uncaught async errors — app must not crash
  debugPrint('Unhandled error: $error');
}
