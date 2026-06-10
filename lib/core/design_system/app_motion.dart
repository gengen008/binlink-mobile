import 'package:flutter/material.dart';

/// BDOS Design Tokens — Motion System
/// 
/// Precise timing and easing for a premium physical feel.
class AppMotion {
  AppMotion._();

  // ── Durations ─────────────────────────────────────────────────────────────
  /// Micro-interactions (toggles, selection)
  static const Duration fast   = Duration(milliseconds: 150); 
  
  /// Components (button presses, card hover)
  static const Duration normal = Duration(milliseconds: 250); 
  
  /// Sheets/Pages (bottom sheet entrance, route transition)
  static const Duration slow   = Duration(milliseconds: 350); 
  
  /// Heavy transitions
  static const Duration max    = Duration(milliseconds: 400); 

  // ── Curves ────────────────────────────────────────────────────────────────
  /// Standard snappy easing for most UI movements.
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasized curve for high-profile entrances like hero banners or primary sheets.
  static const Curve emphasized = Curves.easeOutQuart;
}
