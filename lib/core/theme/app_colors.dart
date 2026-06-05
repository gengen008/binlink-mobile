import 'package:flutter/material.dart';

/// BinLink Design System — Color Tokens
///
/// Dark-theme app. All Rydr layout zones are mapped here to BinLink's
/// navy palette so every screen can consume tokens instead of hex literals.
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color midnightNavy = Color(0xFF021024);
  static const Color deepOcean    = Color(0xFF052659);
  static const Color steelBlue    = Color(0xFF5483B3);
  static const Color skyBlue      = Color(0xFF7DA0CA);
  static const Color iceBlue      = Color(0xFFC1E8FF);
  static const Color white        = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color danger       = Color(0xFFEF4444);
  static const Color muted        = Color(0xFF64748B);

  // ── Surface hierarchy (Rydr light theme) ────────────────────────────────────
  /// Page/scaffold background — Rydr: ColorPath.Primarywhite
  static const Color surface      = Color(0xFFFFFFFF);
  /// Card, sheet, dialog background — Rydr: ColorPath.Primaryfield
  static const Color card         = Color(0xFFDCE1DE);
  /// Elevated card (slightly darker than card)
  static const Color cardElevated = Color(0xFFCDD3D1);
  /// Subtle border / divider
  static const Color border       = Color(0xFF1A3A5C);
  /// Strong border (active input, focus ring)
  static const Color borderActive = Color(0xFF5483B3);

  // ── AppBar / Navigation ────────────────────────────────────────────────────
  /// AppBar background — matches Rydr's dark header
  static const Color appBarBg     = deepOcean;
  /// AppBar action button container (Rydr uses a rounded box for the drawer icon)
  static const Color appBarAction = Color(0xFF1A3A5C);
  /// Bottom navigation bar background
  static const Color navBarBg     = deepOcean;

  // ── Drawer (Rydr RyderDrawer pattern) ─────────────────────────────────────
  static const Color drawerBg     = Color(0xFF071830);
  static const Color drawerItem   = iceBlue;
  static const Color drawerMuted  = skyBlue;

  // ── Form fields — Rydr: ColorPath.Primaryfield = Color(0xFFDCE1DE) ──────────
  /// Field fill — Rydr: ColorPath.Primaryfield light grey
  static const Color fieldFill    = Color(0xFFDCE1DE);
  /// Field fill when focused (slightly darker)
  static const Color fieldFillFocused = Color(0xFFCDD3D1);
  /// Placeholder / hint text inside fields
  static const Color fieldHint    = Color(0xFF64748B);

  // ── Sheet / Bottom sheet ───────────────────────────────────────────────────
  /// Background of modal bottom sheets — Rydr: white
  static const Color sheetBg      = Color(0xFFFFFFFF);
  /// Drag handle colour (Rydr: Primaryfield)
  static const Color sheetHandle  = Color(0xFF1A3A5C);

  // ── Overlay / Scrim ────────────────────────────────────────────────────────
  static const Color scrim        = Color(0x99000000);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// Primary text — Rydr: ColorPath.Primarydark = Color(0xFF1F2421) ≈ midnightNavy
  static const Color textPrimary   = midnightNavy;
  static const Color textSecondary = skyBlue;
  /// Body text (Rydr: Primarydark)
  static const Color textBody      = midnightNavy;
  /// Subtle / de-emphasised text (Rydr: grey labels, timestamps)
  static const Color textMuted     = muted;
  /// Text on dark filled buttons / dark-bg overlays
  static const Color textOnDark    = white;

  // ── Status chip colors ─────────────────────────────────────────────────────
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

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Page background gradient — Rydr: white / near-white light theme
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F6F5)],
  );

  /// Primary action gradient (buttons, active indicators)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [steelBlue, skyBlue],
  );

  /// Card gradient (Rydr: Primarydark → darker variant)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, cardElevated],
  );

  /// Wallet / balance card gradient (Rydr: dark card with background image)
  static const LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepOcean, Color(0xFF0A3070)],
  );
}
