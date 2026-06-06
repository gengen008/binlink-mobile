import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// BinLink "Base" Design System — Typography Tokens
///
/// REQUIRED: Plus Jakarta Sans (UI) + DM Mono (numbers, prices, refs)
class AppTextStyles {
  AppTextStyles._();

  // ── Primary Hierarchy ──────────────────────────────────────────────────────

  /// 30/700 — Hero headings, large splash text
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  /// 20/700 — Main section headers
  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// 15/700 — Secondary section headers, emphasized labels
  static TextStyle get section => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  /// 14/400 — Standard body copy
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// 14/500 — Medium weight body copy (semi-bold feel)
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// 12/500 — Metadata, small labels, secondary info
  static TextStyle get meta => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// 11/500 — Captions, micro-copy, chips
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Operational / Mono ─────────────────────────────────────────────────────

  /// 24/600 — Large metrics (earnings)
  static TextStyle get monoLg => GoogleFonts.dmMono(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// 14/500 — Standard metrics
  static TextStyle get mono => GoogleFonts.dmMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoSm => GoogleFonts.dmMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Semantic Aliases (Required by existing codebase) ──────────────────────
  static TextStyle get h1 => display;
  static TextStyle get h2 => title;
  static TextStyle get h3 => section;
  static TextStyle get h4 => section.copyWith(fontSize: 16);
  static TextStyle get bodySmall => body.copyWith(fontSize: 13);
  static TextStyle get label => meta;
  static TextStyle get chip => caption;
  static TextStyle get drawerTitle => section.copyWith(color: Colors.white);
  static TextStyle get drawerItem  => bodyMedium;
  static TextStyle get buttonSm   => meta.copyWith(fontWeight: FontWeight.w700);
  static TextStyle get appBarSub  => caption;

  // ── UI Element Aliases ─────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get appBarTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
}
