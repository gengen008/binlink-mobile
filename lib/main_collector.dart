import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_flavor.dart';
import 'app.dart';

void main() {
  runZonedGuarded(_appMain, _handleError);
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  FlavorConfig.flavor = AppFlavor.collector;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env failed to load — app will use fallback URLs from Env class
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
  // Silently swallow uncaught async errors — app must not crash
  debugPrint('Unhandled error: $error');
}
