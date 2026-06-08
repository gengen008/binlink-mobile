import 'package:flutter/material.dart';
import '../config/app_flavor.dart';

/// BinLink "Base" Design System — Color Tokens
/// 
/// Updated for V3: Flavor-aware color palette.
class AppColors {
  AppColors._();

  // ── Brand Identity ─────────────────────────────────────────────────────────
  static const Color black        = Color(0xFF000000); // Uber Black
  static const Color premiumBlack = Color(0xFF080808); // Deep surface
  static const Color boltGreen    = Color(0xFF00C244); // Bolt Green (Vivid)
  static const Color electricBlue = Color(0xFF276EF1); // Uber Blue
  static const Color pureWhite    = Color(0xFFFFFFFF);
  
  // ── Flavor Colors ──────────────────────────────────────────────────────────
  // Use Uber Blue for Household and Bolt Green for Collector (operational)
  static const Color householdPrimary = electricBlue;
  static const Color collectorPrimary = boltGreen;

  // ── Dynamic Primary (Flavor Based) ────────────────────────────────────────
  static Color get primary => FlavorConfig.isHousehold ? householdPrimary : collectorPrimary;
  static Color get secondary => black;

  // ── Surface & Neutral ──────────────────────────────────────────────────────
  static const Color background   = Color(0xFFFFFFFF); // Light background
  static const Color surface      = Color(0xFFF3F4F6); // Light gray surface
  static const Color darkSurface  = Color(0xFF111827); // Dark mode surface
  static const Color border       = Color(0xFFE5E7EB); // Subtle borders
  static const Color divider      = Color(0xFFF1F1F1);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF000000); // Absolute black
  static const Color textSecondary = Color(0xFF6B7280); // Slate gray
  static const Color textMuted     = Color(0xFF9CA3AF); 
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // ── Status & States ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24); // Yellow (not orange)
  static const Color danger  = Color(0xFFDC2626);
  static const Color info    = electricBlue;
  static const Color white   = Color(0xFFFFFFFF);

  // ── Legacy Aliases & Missing Tokens ──────────────────────────────────────
  static const Color steelBlue    = electricBlue;
  static const Color appBarAction = surface;

  // ── Semantic Aliases ──────────────────────────────────────────────────────
  static Color get primaryLight     => primary.withAlpha(25);
  static const Color card             = white;
  static const Color cardElevated     = white;
  static const Color appBarBg         = white;
  static const Color fieldFill        = surface;
  static const Color fieldFillFocused = white;
  static const Color sheetHandle      = Color(0xFFE5E7EB);
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
