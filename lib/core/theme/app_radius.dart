import 'package:flutter/material.dart';

/// BinLink Eco — Radius Tokens
///
/// Bolt/Uber-style disciplined radius.
/// Cards / Inputs / Buttons: 12px
/// Sheets (top corners only): 20px
class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────────────────────
  /// 4px — micro badges
  static const double xs = 4.0;

  /// 8px — small badges, status pills
  static const double sm = 8.0;

  /// 12px — inputs, standard cards, buttons
  static const double md = 12.0;

  /// 16px — large feature cards
  static const double lg = 16.0;

  /// 20px — bottom sheets top corners
  static const double sheet = 20.0;

  /// 999px — fully circular
  static const double full = 999.0;

  // ── Back-compat / Alias ──────────────────────────────────────────────────
  static const double field  = md;
  static const double button = md;
  static const double xl     = lg;
  static const double xxl    = lg;

  // ── BorderRadius getters ───────────────────────────────────────────────────
  static BorderRadius get xsBR     => BorderRadius.circular(xs);
  static BorderRadius get smBR     => BorderRadius.circular(sm);
  static BorderRadius get mdBR     => BorderRadius.circular(md);
  static BorderRadius get fieldBR  => mdBR;
  static BorderRadius get buttonBR => mdBR;
  static BorderRadius get lgBR     => BorderRadius.circular(lg);
  static BorderRadius get xlBR     => lgBR;
  static BorderRadius get fullBR   => BorderRadius.circular(full);

  /// Bottom sheet — rounds only the top two corners
  static const BorderRadius sheetBR = BorderRadius.only(
    topLeft:  Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );

  /// Drawer — rounds only the right two corners
  static const BorderRadius drawerBR = BorderRadius.only(
    topRight:    Radius.circular(md),
    bottomRight: Radius.circular(md),
  );

  static BorderRadius get xxlBR => lgBR;
}
