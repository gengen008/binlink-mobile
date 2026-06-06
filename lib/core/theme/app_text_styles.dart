import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// BinLink Eco — Typography Tokens
///
/// Disciplined Bolt/Uber-style hierarchy.
/// Font: Plus Jakarta Sans (UI)
/// Mono: DM Mono (Metrics/Prices)
class AppTextStyles {
  AppTextStyles._();

  // ── Scale ───────────────────────────────────────────────────────────────

  /// 30/700 — Hero headings, large splash text
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  /// 20/700 — Main section headers
  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  /// 15/700 — Secondary section headers, emphasized labels
  static TextStyle get section => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  /// 14/400 — Standard body copy
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  /// 14/500 — Medium weight body copy (semi-bold feel)
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  /// 12/500 — Metadata, small labels, secondary info
  static TextStyle get meta => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      );

  /// 11/500 — Captions, micro-copy, chips
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0,
      );

  // ── Semantic Aliases ───────────────────────────────────────────────────────
  static TextStyle get h1 => display;
  static TextStyle get h2 => title.copyWith(fontSize: 22);
  static TextStyle get h3 => section.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get h4 => section.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get appBarTitle => title.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get appBarSub   => meta.copyWith(fontWeight: FontWeight.w400);

  static TextStyle get drawerTitle => section.copyWith(color: Colors.white);
  static TextStyle get drawerItem  => bodyMedium.copyWith(color: AppColors.drawerItem);

  static TextStyle get label => meta;
  static TextStyle get bodySmall => body.copyWith(fontSize: 13, height: 1.4);
  static TextStyle get chip => caption;

  // ── Buttons ───────────────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0,
      );

  static TextStyle get buttonSecondary => bodyMedium;
  static TextStyle get buttonSm => meta.copyWith(color: AppColors.white, fontWeight: FontWeight.w600);

  // ── Mono — metrics ────────────────────────────────────────────────────────
  static TextStyle get monoLg => GoogleFonts.dmMono(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get mono => GoogleFonts.dmMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoSm => GoogleFonts.dmMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}
