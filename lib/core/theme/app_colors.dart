import 'package:flutter/material.dart';

/// BinLink Eco — Design System Color Tokens
///
/// Eco-logistics green/slate palette.
/// Architecture: Trippo screen hierarchy + BinLink business logic.
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF16A34A); // eco green
  static const Color accent    = Color(0xFF22C55E); // lighter green
  static const Color secondary = Color(0xFF0F172A); // deep slate

  // ── Legacy aliases (keep existing screens compiling during migration) ───────
  static const Color midnightNavy = secondary;
  static const Color deepOcean    = Color(0xFF1E293B);
  static const Color steelBlue    = primary;
  static const Color skyBlue      = accent;
  static const Color iceBlue      = Color(0xFFD1FAE5); // light green tint
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
  static const Color borderActive = primary;            // focus ring

  // ── AppBar / Navigation ────────────────────────────────────────────────────
  static const Color appBarBg     = secondary;
  static const Color appBarAction = Color(0xFF1E293B);
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
  static const Color textSecondary = primary;  // green accent text
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
        return primary;
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
    colors: [Color(0xFFF8FAFC), Color(0xFFECFDF5)],
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
    colors: [primary, Color(0xFF0D9348)],
  );
}
