import 'package:flutter/material.dart';

/// BinLink "Base" Design System — Radius Tokens
///
/// World-class mobility standard: 16px.
class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────────────────────
  /// 8px — micro badges
  static const double xs = 8.0;

  /// 12px — status pills
  static const double sm = 12.0;

  /// 16px — Standard Radius (Cards, Buttons, Inputs)
  static const double md = 16.0;

  /// 24px — Bottom sheets top corners
  static const double lg = 24.0;

  /// 999px — fully circular
  static const double full = 999.0;

  // ── BorderRadius getters ───────────────────────────────────────────────────
  static BorderRadius get xsBR     => BorderRadius.circular(xs);
  static BorderRadius get smBR     => BorderRadius.circular(sm);
  static BorderRadius get mdBR     => BorderRadius.circular(md);
  static BorderRadius get lgBR     => BorderRadius.circular(lg);
  static BorderRadius get fullBR   => BorderRadius.circular(full);

  /// Standard for all interactive components
  static BorderRadius get standard => mdBR;

  /// Bottom sheet — rounds only the top two corners
  static const BorderRadius sheetBR = BorderRadius.only(
    topLeft:  Radius.circular(lg),
    topRight: Radius.circular(lg),
  );

  /// Back-compat aliases
  static BorderRadius get fieldBR  => mdBR;
  static BorderRadius get buttonBR => mdBR;
  static BorderRadius get xlBR     => lgBR;
}
