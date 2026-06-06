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
  static const Color secondary    = Color(0xFF0F172A); // near-black (text, icons)

  // ── Legacy blue range (kept for map overlays / status chips only) ───────────
  static const Color steelBlue = Color(0xFF5483B3);
  static const Color skyBlue   = Color(0xFF7DA0CA);
  static const Color iceBlue   = Color(0xFFC1E8FF);
  static const Color deepOcean = Color(0xFF052659);
  static const Color midnightNavy = Color(0xFF021024);
  static const Color white        = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color muted   = Color(0xFF64748B);

  // ── Surface hierarchy (Uber/Bolt neutral) ──────────────────────────────────
  static const Color surface      = Color(0xFFF8FAFC); // page / scaffold bg
  static const Color card         = Color(0xFFFFFFFF); // card / sheet bg
  static const Color cardElevated = Color(0xFFF1F5F9); // subtle elevated card
  static const Color border       = Color(0xFFE2E8F0); // divider / outline
  static const Color borderActive = primary;            // focus ring

  // ── AppBar / Navigation ────────────────────────────────────────────────────
  static const Color appBarBg     = card;
  static const Color appBarAction = surface;
  static const Color navBarBg     = card;

  // ── Drawer ─────────────────────────────────────────────────────────────────
  static const Color drawerBg    = secondary;
  static const Color drawerItem  = Color(0xFFCBD5E1);
  static const Color drawerMuted = Color(0xFF94A3B8);

  // ── Form fields ───────────────────────────────────────────────────────────
  static const Color fieldFill        = Color(0xFFF1F5F9);
  static const Color fieldFillFocused = Color(0xFFE2E8F0);
  static const Color fieldHint        = muted;

  // ── Sheets ─────────────────────────────────────────────────────────────────
  static const Color sheetBg     = card;
  static const Color sheetHandle = border;

  // ── Scrim ─────────────────────────────────────────────────────────────────
  static const Color scrim = Color(0x99000000);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = secondary;           // #0F172A near-black
  static const Color textSecondary = Color(0xFF475569);   // slate-600 neutral
  static const Color textBody      = secondary;
  static const Color textMuted     = muted;               // slate-500
  static const Color textOnDark    = white;
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
        return muted;
    }
  }

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryMid],
  );
}
