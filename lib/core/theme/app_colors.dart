import 'package:flutter/material.dart';

/// BinLink Eco — Design System Color Tokens
///
/// Bolt/Uber-inspired neutral system with BinLink green as the sole CTA color.
/// White surfaces, near-black text, slate neutrals, green for all interactive states.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF16A34A); // BinLink green — all CTAs
  static const Color primaryLight = Color(0xFFDCFCE7); // light green tint (chips, badges)
  static const Color primaryMid   = Color(0xFF22C55E); // hover / active green
  static const Color secondary    = Color(0xFF111827); // near-black charcoal (text, icons)
  static const Color white        = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color muted   = Color(0xFF64748B);

  // ── Surface hierarchy (Uber/Bolt neutral) ──────────────────────────────────
  static const Color surface      = Color(0xFFF6F7F8); // page / scaffold bg
  static const Color card         = Color(0xFFFFFFFF); // card / sheet bg
  static const Color cardElevated = Color(0xFFF9FAFB); // subtle elevated card
  static const Color border       = Color(0xFFE5E7EB); // divider / outline (Grey 200)
  static const Color borderActive = primary;            // focus ring

  // ── AppBar / Navigation ────────────────────────────────────────────────────
  static const Color appBarBg     = card;
  static const Color appBarAction = surface;
  static const Color navBarBg     = card;

  // ── Drawer ─────────────────────────────────────────────────────────────────
  static const Color drawerBg    = secondary;
  static const Color drawerItem  = Color(0xFF9CA3AF); // Grey 400
  static const Color drawerMuted = Color(0xFF6B7280); // Grey 500

  // ── Form fields ───────────────────────────────────────────────────────────
  static const Color fieldFill        = Color(0xFFF3F4F6); // Grey 100
  static const Color fieldFillFocused = Color(0xFFFFFFFF);
  static const Color fieldHint        = Color(0xFF9CA3AF);

  // ── Sheets ─────────────────────────────────────────────────────────────────
  static const Color sheetBg     = card;
  static const Color sheetHandle = Color(0xFFD1D5DB); // Grey 300

  // ── Scrim ─────────────────────────────────────────────────────────────────
  static const Color scrim = Color(0x99000000);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = secondary;           // #111827 near-black
  static const Color textSecondary = Color(0xFF4B5563);   // Grey 600
  static const Color textBody      = secondary;
  static const Color textMuted     = Color(0xFF6B7280);   // Grey 500
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textLink      = primary;             // green links

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
        return const Color(0xFF9CA3AF);
    }
  }

  // ── Gradients (Minimal use only) ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryMid],
  );
}
