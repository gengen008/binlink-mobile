import 'package:flutter/material.dart';

/// BinLink Design System — Radius Tokens
///
/// Rydr uses raw BorderRadius.circular(n) inline everywhere.
/// Centralised here so every screen uses the same values consistently.
class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────────────────────
  /// 6px — very small chips, small badges
  static const double xs   = 6.0;

  /// 8px — buttons, action chips (Rydr: BorderRadius.circular(8))
  static const double sm   = 8.0;

  /// 9px — form fields (Rydr: BorderRadius.circular(9) on TextFields)
  static const double field = 9.0;

  /// 12px — standard cards
  static const double md   = 12.0;

  /// 14px — elevated cards, input fields
  static const double lg   = 14.0;

  /// 16px — large cards, drawers
  static const double xl   = 16.0;

  /// 20px — bottom sheets top corners (Rydr: 15-25px)
  static const double sheet = 20.0;

  /// 25px — large rounded containers (Rydr: FavoriteItems 25px)
  static const double xxl  = 25.0;

  /// 999px — fully circular (avatars, pill badges)
  static const double full = 999.0;

  // ── BorderRadius getters ───────────────────────────────────────────────────
  static BorderRadius get xsBR    => BorderRadius.circular(xs);
  static BorderRadius get smBR    => BorderRadius.circular(sm);
  static BorderRadius get fieldBR => BorderRadius.circular(field);
  static BorderRadius get mdBR    => BorderRadius.circular(md);
  static BorderRadius get lgBR    => BorderRadius.circular(lg);
  static BorderRadius get xlBR    => BorderRadius.circular(xl);
  static BorderRadius get xxlBR   => BorderRadius.circular(xxl);
  static BorderRadius get fullBR  => BorderRadius.circular(full);

  /// Bottom sheet — only rounds the top two corners (Rydr pattern)
  static const BorderRadius sheetBR = BorderRadius.only(
    topLeft:  Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );

  /// Drawer — only rounds the right two corners (Rydr: ClipRRect pattern)
  static const BorderRadius drawerBR = BorderRadius.only(
    topRight:    Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );
}
