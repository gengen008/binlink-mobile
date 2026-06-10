import 'package:flutter/material.dart';

/// BDOS Design Tokens — Brand & Semantic Color Palette
/// 
/// Owns the "Eco Logistics" identity.
class AppColors {
  AppColors._();

  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color ecoGreen      = Color(0xFF00D166); // Bolt/Spotify tier Green
  static const Color deepCarbon    = Color(0xFF0F172A); // Premium Navy/Black
  static const Color recyclingBlue = Color(0xFF3B82F6); // Trust/Logistics Blue
  static const Color rewardGold    = Color(0xFFF59E0B); // Action/Value Gold

  // ── Functional/Semantic ────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Neutrals (Slate/Zinc) ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE2E8F0);
  static const Color divider    = Color(0xFFF1F5F9);
  
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFF94A3B8);

  // ── Functional Aliases ─────────────────────────────────────────────────────
  static const Color primary   = ecoGreen;
  static const Color secondary = deepCarbon;
  static const Color accent    = recyclingBlue;
}
