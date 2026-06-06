import 'package:flutter/material.dart';

/// BinLink Eco — Radius Tokens
///
/// Cards / Inputs / Buttons: 12px
/// Sheets (top corners only): 20px
class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────────────────────
  /// 4px — micro badges, tight chips
  static const double xs = 4.0;

  /// 8px — small badges, status pills
  static const double sm = 8.0;

  /// 12px — inputs (text fields)
  static const double field = 12.0;

  /// 12px — standard cards
  static const double md = 12.0;

  /// 12px — buttons
  static const double button = 12.0;

  /// 16px — feature cards, larger containers
  static const double lg = 16.0;

  /// 20px — bottom sheets top corners
  static const double sheet = 20.0;

  /// 24px — extra large containers
  static const double xl  = 24.0;

  /// 24px — backward-compat alias for xl
  static const double xxl = xl;

  /// 999px — fully circular (avatars, pill badges)
  static const double full = 999.0;

  // ── BorderRadius getters ───────────────────────────────────────────────────
  static BorderRadius get xsBR     => BorderRadius.circular(xs);
  static BorderRadius get smBR     => BorderRadius.circular(sm);
  static BorderRadius get fieldBR  => BorderRadius.circular(field);
  static BorderRadius get mdBR     => BorderRadius.circular(md);
  static BorderRadius get buttonBR => BorderRadius.circular(button);
  static BorderRadius get lgBR     => BorderRadius.circular(lg);
  static BorderRadius get xlBR     => BorderRadius.circular(xl);
  static BorderRadius get fullBR   => BorderRadius.circular(full);

  /// Bottom sheet — rounds only the top two corners
  static const BorderRadius sheetBR = BorderRadius.only(
    topLeft:  Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );

  /// Drawer — rounds only the right two corners
  static const BorderRadius drawerBR = BorderRadius.only(
    topRight:    Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );

  // ── Backward-compat aliases ────────────────────────────────────────────────
  static BorderRadius get xxlBR => BorderRadius.circular(xl);
}
