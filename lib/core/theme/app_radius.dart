import 'package:flutter/material.dart';

/// BinLink Eco — Radius Tokens
///
/// Inputs / Cards / Buttons: 20
/// Sheets (top corners only): 28
class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────────────────────
  /// 6px — very small chips, micro badges
  static const double xs = 6.0;

  /// 12px — small badges, status pills
  static const double sm = 12.0;

  /// 20px — inputs (text fields)
  static const double field = 20.0;

  /// 20px — standard cards
  static const double md = 20.0;

  /// 20px — buttons
  static const double button = 20.0;

  /// 24px — large feature cards
  static const double lg = 24.0;

  /// 28px — bottom sheets top corners
  static const double sheet = 28.0;

  /// 32px — extra large containers
  static const double xl  = 32.0;

  /// 32px — backward-compat alias for xl
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

  // ── Backward-compat aliases used by existing screens ──────────────────────
  static BorderRadius get xxlBR => BorderRadius.circular(xl);
}
