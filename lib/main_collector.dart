import 'dart:async';
import 'package:flutter/material.dart';
import 'core/config/app_flavor.dart';
import 'core/config/core_initializer.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    await CoreInitializer.init(AppFlavor.collector);
    runApp(const BinLinkApp());
  }, CoreInitializer.handleError);
}
