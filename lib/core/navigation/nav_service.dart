import 'package:flutter/material.dart';

class NavService {
  NavService._();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic>? pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static void pushNamedAndRemoveUntil(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }
}
