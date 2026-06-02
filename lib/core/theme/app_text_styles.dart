import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _sans = 'PlusJakartaSans';
  static const String _mono = 'DMMono';

  // ── Headings (Plus Jakarta Sans) ───────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _sans, fontSize: 28, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _sans, fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: _sans, fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: _sans, fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Body (Plus Jakarta Sans) ───────────────────────────────────
  static const TextStyle body = TextStyle(
    fontFamily: _sans, fontSize: 15, fontWeight: FontWeight.w400,
    height: 1.5, color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _sans, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle label = TextStyle(
    fontFamily: _sans, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _sans, fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // ── Monospace (DM Mono) — prices, distances, times ─────────────
  static const TextStyle monoLg = TextStyle(
    fontFamily: _mono, fontSize: 24, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: _mono, fontSize: 16, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle monoSm = TextStyle(
    fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // ── Button ─────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _sans, fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: 0.2, color: AppColors.white,
  );
}
