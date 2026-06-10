import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// BINLINK V4 — Typography System
/// Headings: Plus Jakarta Sans
/// Body: Inter
class AppTextStyles {
  AppTextStyles._();

  // ── Headings (Plus Jakarta Sans) ──────────────────────────────────────────

  /// 48/800 — Ultra Hero text
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.5,
      );

  /// 32/800 — Page Headers
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  /// 28/700 — Section Headers
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  /// 24/700 — Sub-headers
  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// 20/600 — Card Titles / Feature Titles
  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Body & Meta (Inter) ───────────────────────────────────────────────────

  /// 16/400 — Primary Body
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// 14/400 — Secondary Body / Labels
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// 12/500 — Meta info
  static TextStyle get small => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );

  // ── UI Components ─────────────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get appBarTitle => h3.copyWith(fontSize: 22, letterSpacing: -0.5);

  // ── Operational (Numbers) ──────────────────────────────────────────────────
  static TextStyle get mono => GoogleFonts.dmMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoSm => GoogleFonts.dmMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoLg => GoogleFonts.dmMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Legacy Compatibility (Internal use) ──────────────────────────────────
  static TextStyle get h4 => title.copyWith(fontSize: 16);
  static TextStyle get bodyMedium => body.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get bodySmall => caption;
  static TextStyle get label => small.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w600);
  static TextStyle get chip => small;
  static TextStyle get meta => small;
  static TextStyle get section => h4.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2);
}
