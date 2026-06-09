import 'dart:async';
import 'package:flutter/material.dart';
import 'core/config/app_flavor.dart';
import 'core/config/core_initializer.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    // default to household for main.dart
    await CoreInitializer.init(AppFlavor.household);
    runApp(const BinLinkApp());
  }, CoreInitializer.handleError);
}
