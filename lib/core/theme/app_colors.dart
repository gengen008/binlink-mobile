import 'package:flutter/material.dart';
import '../config/app_flavor.dart';

/// BINLINK V3 — Mandatory Color Palette
/// Derived from Uber/Bolt design directives.
class AppColors {
  AppColors._();

  // ── Mandatory Primary Palette (Household / Core) ───────────────────────────
  // Updated to High-Energy Bolt Green
  static const Color primary900 = Color(0xFF022C22); // Darker Green
  static const Color primary800 = Color(0xFF064E3B);
  static const Color primary700 = Color(0xFF047857);
  static const Color primary600 = Color(0xFF22C55E); // High-Energy Bolt Green
  static const Color primary500 = Color(0xFF4ADE80);
  static const Color primary300 = Color(0xFF86EFAC);

  // ── Collector Brand (Amber/Orange) ─────────────────────────────────────────
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber100 = Color(0xFFFEF3C7);

  // ── Base Colors ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color black      = Color(0xFF000000);
  static const Color premiumBlack = Color(0xFF0F172A);
  static const Color white      = Color(0xFFFFFFFF);

  // ── Semantic Status Colors ─────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color boltGreen = Color(0xFF34D399);

  // ── Neutral Palette (Slate/Gray) ───────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Near black
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted     = Color(0xFF94A3B8); // Slate 400
  static const Color border        = Color(0xFFE2E8F0); // Slate 200
  static const Color divider       = Color(0xFFF1F5F9); // Slate 100

  // ── Field Styles ───────────────────────────────────────────────────────────
  static const Color fieldFill        = Color(0xFFF1F5F9);
  static const Color fieldFillFocused = Color(0xFFFFFFFF);
  static const Color borderActive     = primary900;

  // ── Card Styles ────────────────────────────────────────────────────────────
  static const Color card         = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFFFFFF);

  // ── Functional Aliases ─────────────────────────────────────────────────────
  static Color get primary      => FlavorConfig.isCollector ? amber500 : primary600;
  static Color get secondary    => FlavorConfig.isCollector ? amber600 : primary700;
  static Color get primaryLight => FlavorConfig.isCollector ? amber100 : primary300;
  
  static const Color danger       = error;
  static const Color muted        = textMuted;
  
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING':
        return warning;
      case 'ASSIGNED':
      case 'ACCEPTED':
      case 'ARRIVED':
      case 'COLLECTING':
      case 'COLLECTED':
      case 'COMPLETED':
        return success;
      case 'EN_ROUTE':
      case 'ON_THE_WAY':
        return primary600;
      case 'CANCELLED':
        return error;
      default:
        return textSecondary;
    }
  }
}
