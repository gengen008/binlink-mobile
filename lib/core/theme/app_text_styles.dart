import 'package:flutter/material.dart';
import 'app_colors.dart';

/// BinLink Design System — Typography Tokens
///
/// Font mapping from Rydr (Montserrat + Poppins) → BinLink (Plus Jakarta Sans + DM Mono)
///
/// Rydr size reference:
///   26px heading   → h1 (28px)
///   20px title     → h2 (22px)   [screen titles, drawer header]
///   18px title     → h3 (18px)   [section headers]
///   17px appbar    → appBarTitle (17px)
///   15px drawer    → drawerTitle (15px)
///   13px label     → label (13px)
///   12px body      → body (12px)
///   11px small     → bodySmall (11px)
///   10px appbar sub→ appBarSub (10px)
///   9px chip/time  → chip (9px)
class AppTextStyles {
  AppTextStyles._();

  static const String _sans = 'PlusJakartaSans';
  static const String _mono = 'DMMono';

  // ── Headings ───────────────────────────────────────────────────────────────
  /// 28px ExtraBold — Rydr choose_auth "Enjoy a new car experience" (26px Montserrat Bold)
  static const TextStyle h1 = TextStyle(
    fontFamily: _sans,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// 22px Bold — Rydr screen titles, bottom sheet titles ("Set favorite location")
  static const TextStyle h2 = TextStyle(
    fontFamily: _sans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// 18px Bold — Rydr login "Welcome Back" (18px Montserrat w500)
  static const TextStyle h3 = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 16px Bold — section headers, card titles
  static const TextStyle h4 = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── AppBar titles (Rydr: Poppins / Montserrat 17-18px) ─────────────────────
  /// 17px SemiBold — AppBar main greeting (Rydr: Poppins w400 17px)
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 10px Regular — AppBar subtitle line (Rydr: Poppins w400 10px)
  static const TextStyle appBarSub = TextStyle(
    fontFamily: _sans,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Drawer (Rydr: Montserrat 15px w600 / 12px w600) ───────────────────────
  /// 15px SemiBold — drawer profile name
  static const TextStyle drawerTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 12px SemiBold — drawer list tile items
  static const TextStyle drawerItem = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body text (Rydr: Montserrat 12-13px) ───────────────────────────────────
  /// 15px Regular — standard body copy
  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 15px SemiBold — emphasized body
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 13px SemiBold — labels, form hints (Rydr: Montserrat w600 13px)
  static const TextStyle label = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  /// 12px Regular — secondary body, description text (Rydr: Montserrat w400 12px)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textBody,
  );

  /// 11px Medium — Rydr sub-description (Montserrat w300 11px)
  static const TextStyle caption = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  /// 9px Regular — chip labels, timestamps (Rydr: Montserrat w300 9px)
  static const TextStyle chip = TextStyle(
    fontFamily: _sans,
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // ── Buttons (Rydr: Poppins w400/w500) ─────────────────────────────────────
  /// 15px Bold — primary button label
  static const TextStyle button = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.white,
  );

  /// 14px Medium — secondary / outline button label (Rydr: Poppins w400)
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// 10px Medium — small action buttons (Rydr: Poppins w500 10px "Edit Profile")
  static const TextStyle buttonSm = TextStyle(
    fontFamily: _sans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  // ── Monospace (DM Mono) — prices, distances, times ─────────────────────────
  /// 24px SemiBold — wallet balance large amount
  static const TextStyle monoLg = TextStyle(
    fontFamily: _mono,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 16px Medium — inline amounts, distances
  static const TextStyle mono = TextStyle(
    fontFamily: _mono,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 13px Medium — small amounts, ETA labels
  static const TextStyle monoSm = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
