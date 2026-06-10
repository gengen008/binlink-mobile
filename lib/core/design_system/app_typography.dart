import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_font_size.dart';

/// BDOS Design Tokens — Typography System
/// 
/// Strict hierarchy using local font stacks.
class AppTypography {
  AppTypography._();

  // ── Headings (Plus Jakarta Sans ExtraBold) ────────────────────────────────

  static TextStyle get h1 => TextStyle(
        fontFamily: AppFonts.primary,
        fontSize: AppFontSize.display,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: AppFonts.primary,
        fontSize: AppFontSize.xxl,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: AppFonts.primary,
        fontSize: AppFontSize.xl,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Body & UI (Inter) ─────────────────────────────────────────────────────

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'Inter',
        fontSize: AppFontSize.md,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'Inter',
        fontSize: AppFontSize.base,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: 'Inter',
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get button => TextStyle(
        fontFamily: AppFonts.primary,
        fontSize: AppFontSize.md,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  // ── Numeric & Data (DM Mono) ──────────────────────────────────────────────

  static TextStyle get dataLarge => TextStyle(
        fontFamily: AppFonts.numeric,
        fontSize: AppFontSize.xxl,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get dataMedium => TextStyle(
        fontFamily: AppFonts.numeric,
        fontSize: AppFontSize.md,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
      
  static TextStyle get dataSmall => TextStyle(
        fontFamily: AppFonts.numeric,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}
