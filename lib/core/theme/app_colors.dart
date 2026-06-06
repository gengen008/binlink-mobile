import 'package:flutter/material.dart';
import '../config/app_flavor.dart';

/// BinLink "Base" Design System — Color Tokens
/// 
/// Updated for V3: Flavor-aware color palette.
class AppColors {
  AppColors._();

  // ── Brand Identity ─────────────────────────────────────────────────────────
  static const Color navy         = Color(0xFF021024); // Darkest background
  static const Color deepOcean    = Color(0xFF052659); // Secondary surface
  static const Color iceBlue      = Color(0xFFC1E8FF); // Highlights / chips
  
  // ── Flavor Colors ──────────────────────────────────────────────────────────
  static const Color steelBlue    = Color(0xFF5483B3); // Household Primary
  static const Color skyBlue      = Color(0xFF7DA0CA); // Household Secondary
  
  static const Color collectorPrimary = Color(0xFFF59E0B); // Collector Primary (Amber)
  static const Color collectorAccent  = Color(0xFFD97706); // Collector Darker Amber

  // ── Dynamic Primary (Flavor Based) ────────────────────────────────────────
  static Color get primary => FlavorConfig.isHousehold ? steelBlue : collectorPrimary;
  static Color get secondary => FlavorConfig.isHousehold ? skyBlue : collectorAccent;

  // ── Surface & Neutral ──────────────────────────────────────────────────────
  static const Color background   = Color(0xFFFFFFFF); // Pure White
  static const Color surface      = Color(0xFFF6F6F6); // Light Gray Surface
  static const Color border       = Color(0xFFE5E7EB); // Subtle Borders
  static const Color divider      = Color(0xFFEEEEEE);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111111); // Near-Black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // ── Status & States ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
  static const Color white   = Color(0xFFFFFFFF);

  // ── Semantic Aliases ──────────────────────────────────────────────────────
  static Color get primaryLight     => primary.withAlpha(30);
  static const Color textMuted        = Color(0xFF6B7280);
  static const Color card             = background;
  static const Color cardElevated     = Color(0xFFF9FAFB);
  static const Color appBarBg         = background;
  static const Color appBarAction     = surface;
  static const Color fieldFill        = surface;
  static const Color fieldFillFocused = background;
  static const Color fieldHint        = textSecondary;
  static const Color sheetHandle      = Color(0xFFD1D5DB);
  static Color get borderActive       => primary;
  static const Color muted            = textSecondary;

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING':
        return warning;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return success;
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
        return textSecondary;
    }
  }
}
