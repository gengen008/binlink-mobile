import 'package:flutter/material.dart';

/// BDOS Design Tokens — Corner Radius
/// 
/// Uber/Bolt Standard consistency.
class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0; // Standard for cards & sheets
  static const double xl   = 32.0;
  static const double full = 999.0;

  // ── BorderRadius getters ───────────────────────────────────────────────────
  static BorderRadius get xsBR => BorderRadius.circular(xs);
  static BorderRadius get smBR => BorderRadius.circular(sm);
  static BorderRadius get mdBR => BorderRadius.circular(md);
  static BorderRadius get lgBR => BorderRadius.circular(lg);
  static BorderRadius get xlBR => BorderRadius.circular(xl);
  static BorderRadius get fullBR => BorderRadius.circular(full);
}
