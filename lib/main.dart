import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_flavor.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.flavor = AppFlavor.household;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — Env class falls back to hardcoded defaults
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

  // Catch any Flutter framework errors and show a clean screen
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(const BinLinkApp());
}
