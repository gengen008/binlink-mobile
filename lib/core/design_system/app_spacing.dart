import 'package:flutter/material.dart';

/// BDOS Design Tokens — Spacing System
/// 
/// Strict 8pt grid enforcement.
class AppSpacing {
  AppSpacing._();

  static const double unit = 8.0;

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Layout helpers ────────────────────────────────────────────────────────
  static const double screenPadding = 24.0;
  static const double cardPadding = 16.0;
  static const double elementGap = 16.0;
  static const double sectionGap = 32.0;

  // ── EdgeInsets shortcuts ──────────────────────────────────────────────────
  static const EdgeInsets edgeXS = EdgeInsets.all(xs);
  static const EdgeInsets edgeSM = EdgeInsets.all(sm);
  static const EdgeInsets edgeMD = EdgeInsets.all(md);
  static const EdgeInsets edgeLG = EdgeInsets.all(lg);
  
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
}
