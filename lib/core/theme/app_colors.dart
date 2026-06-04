import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────
  static const Color midnightNavy = Color(0xFF021024);
  static const Color deepOcean    = Color(0xFF052659);
  static const Color steelBlue    = Color(0xFF5483B3);
  static const Color skyBlue      = Color(0xFF7DA0CA);
  static const Color iceBlue      = Color(0xFFC1E8FF);
  static const Color white        = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color danger       = Color(0xFFEF4444);
  static const Color muted        = Color(0xFF64748B);

  // ── Surfaces ───────────────────────────────────────────────────
  static const Color surface      = Color(0xFF0A1929);   // slightly lighter than navy
  static const Color card         = Color(0xFF0D2137);   // card background
  static const Color border       = Color(0xFF1A3A5C);   // subtle border

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary   = white;
  static const Color textSecondary = skyBlue;
  static const Color textMuted     = muted;

  // ── Status chip colors ─────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':    return warning;
      case 'SEARCHING':  return warning;
      case 'ASSIGNED':   return steelBlue;
      case 'ACCEPTED':   return steelBlue;
      case 'EN_ROUTE':   return warning;
      case 'ON_THE_WAY': return warning;
      case 'ARRIVED':    return success;
      case 'COLLECTING': return success;
      case 'COLLECTED':  return success;
      case 'COMPLETED':  return success;
      case 'CANCELLED':  return danger;
      default:           return muted;
    }
  }

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightNavy, deepOcean],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [steelBlue, skyBlue],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, Color(0xFF0F2847)],
  );
}
