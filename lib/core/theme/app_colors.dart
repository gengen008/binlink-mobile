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

  // ── Surface hierarchy (dark theme) ─────────────────────────────────────────
  /// Page/scaffold background
  static const Color surface      = Color(0xFF0A1929);
  /// Card, sheet, dialog background
  static const Color card         = Color(0xFF0D2137);
  /// Elevated card (one level above card)
  static const Color cardElevated = Color(0xFF0F2847);
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

  // ── Form fields (Rydr Primaryfield = #DCE1DE at opacity 0.3 → dark equiv.) ─
  /// Field fill — used for TextFormField background
  static const Color fieldFill    = Color(0xFF0D2137);
  /// Field fill when focused
  static const Color fieldFillFocused = Color(0xFF0F2847);
  /// Placeholder / hint text inside fields
  static const Color fieldHint    = Color(0xFF64748B);

  // ── Sheet / Bottom sheet ───────────────────────────────────────────────────
  /// Background of modal bottom sheets
  static const Color sheetBg      = Color(0xFF0D2137);
  /// Drag handle colour (Rydr: Primaryfield)
  static const Color sheetHandle  = Color(0xFF1A3A5C);

  // ── Overlay / Scrim ────────────────────────────────────────────────────────
  static const Color scrim        = Color(0x99000000);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = white;
  static const Color textSecondary = skyBlue;
  /// Body text on dark surfaces (Rydr: offBlack #50555C → our muted)
  static const Color textBody      = Color(0xFFB0C4DE);
  /// Subtle / de-emphasised text (Rydr: grey labels, timestamps)
  static const Color textMuted     = muted;
  /// Text on dark filled buttons (Rydr: SecondaryColor #F3F3C1 → iceBlue)
  static const Color textOnDark    = iceBlue;

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
  /// Page background gradient
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightNavy, deepOcean],
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
