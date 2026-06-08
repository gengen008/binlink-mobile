import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// BinLink "V4" Typography System
///
/// Uber/Bolt Standard: Ultra-bold headers, high-contrast, professional.
class AppTextStyles {
  AppTextStyles._();

  // ── Headers (Plus Jakarta Sans) ──────────────────────────────────────────

  /// 32/800 — Ultra-bold hero text
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  /// 24/700 — Bold section headers
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  /// 18/700 — Compact bold headers
  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// 16/600 — Semi-bold labels
  static TextStyle get h4 => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Body ──────────────────────────────────────────────────────────────────

  /// 16/500 — Primary body (Standard Uber/Bolt size)
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// 14/500 — Secondary body
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// 12/600 — Meta labels
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );

  // ── Operational (DM Mono) ──────────────────────────────────────────────────

  /// 26/600 — Large Prices/Numbers
  static TextStyle get monoLg => GoogleFonts.dmMono(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// 16/500 — Standard Numbers
  static TextStyle get mono => GoogleFonts.dmMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // ── UI Components ─────────────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get appBarTitle => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Legacy Aliases & Missing Tokens ──────────────────────────────────────
  static TextStyle get monoSm       => mono.copyWith(fontSize: 12);
  static TextStyle get appBarSub    => label;
  static TextStyle get drawerTitle  => h3;
  static TextStyle get drawerItem   => h4;
  static TextStyle get buttonSm     => button.copyWith(fontSize: 14);

  // ── Legacy Aliases ────────────────────────────────────────────────────────
  static TextStyle get display    => h1;
  static TextStyle get title      => h2;
  static TextStyle get section    => h3;
  static TextStyle get bodyMedium => body.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get meta       => label;
  static TextStyle get caption    => label.copyWith(fontSize: 11);
  static TextStyle get chip       => caption;
}
