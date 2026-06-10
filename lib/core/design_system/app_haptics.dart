import 'package:flutter/services.dart';

/// BDOS Design Tokens — Haptic Feedback System
/// 
/// Physical connection for key digital actions.
class AppHaptics {
  AppHaptics._();

  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light()     => HapticFeedback.lightImpact();
  static Future<void> medium()    => HapticFeedback.mediumImpact();
  static Future<void> heavy()     => HapticFeedback.heavyImpact();
  
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  static Future<void> error() async {
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.vibrate();
  }
}
