import 'package:flutter/material.dart';

/// BinLink Eco — Design System Color Tokens
///
/// Navy / steel-blue palette per brand spec.
/// #021024 navy, #052659 deep ocean, #5483B3 steel, #7DA0CA sky, #C1E8FF ice
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF16A34A); // eco green (CTA / brand buttons)
  static const Color accent    = Color(0xFF22C55E); // lighter green (hover / accent)
  static const Color secondary = Color(0xFF021024); // midnight navy

  // ── Steel-blue range (brand spec) ─────────────────────────────────────────
  static const Color midnightNavy = Color(0xFF021024); // #021024
  static const Color deepOcean    = Color(0xFF052659); // #052659
  static const Color steelBlue    = Color(0xFF5483B3); // #5483B3
  static const Color skyBlue      = Color(0xFF7DA0CA); // #7DA0CA
  static const Color iceBlue      = Color(0xFFC1E8FF); // #C1E8FF
  static const Color white        = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color muted   = Color(0xFF64748B);

  // ── Surface hierarchy ──────────────────────────────────────────────────────
  static const Color surface      = Color(0xFFF8FAFC); // page / scaffold bg
  static const Color card         = Color(0xFFFFFFFF); // card / sheet bg
  static const Color cardElevated = Color(0xFFF1F5F9); // subtle elevated card
  static const Color border       = Color(0xFFE2E8F0); // divider / outline
  static const Color borderActive = steelBlue;         // focus ring

  // ── AppBar / Navigation ────────────────────────────────────────────────────
  static const Color appBarBg     = secondary;
  static const Color appBarAction = deepOcean;
  static const Color navBarBg     = card;

  // ── Drawer ─────────────────────────────────────────────────────────────────
  static const Color drawerBg    = secondary;
  static const Color drawerItem  = iceBlue;
  static const Color drawerMuted = Color(0xFF94A3B8);

  // ── Form fields ───────────────────────────────────────────────────────────
  static const Color fieldFill        = Color(0xFFF1F5F9);
  static const Color fieldFillFocused = Color(0xFFE2E8F0);
  static const Color fieldHint        = muted;

  // ── Sheet ─────────────────────────────────────────────────────────────────
  static const Color sheetBg     = card;
  static const Color sheetHandle = border;

  // ── Scrim ─────────────────────────────────────────────────────────────────
  static const Color scrim = Color(0x99000000);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = secondary;
  static const Color textSecondary = steelBlue; // steel-blue accent text
  static const Color textBody      = secondary;
  static const Color textMuted     = muted;
  static const Color textOnDark    = white;

  // ── Status chip ───────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING':
        return warning;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return steelBlue;
      case 'EN_ROUTE':
      case 'ON_THE_WAY':
        return warning;
      case 'ARRIVED':
      case 'COLLECTING':
      case 'COLLECTED':
      case 'COMPLETED':
        return success;
      case 'CANCELLED':
        return danger;
      default:
        return muted;
    }
  }

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)], // soft blue tint
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, cardElevated],
  );

  static const LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightNavy, deepOcean],
  );
}
