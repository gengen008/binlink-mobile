import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/binlink_colors.dart';
import '../design_system/binlink_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        colors: const BinLinkColors(
          primary: AppColors.ecoGreen,
          secondary: AppColors.deepCarbon,
          background: AppColors.background,
          surface: AppColors.surface,
          textPrimary: AppColors.textPrimary,
          textSecondary: AppColors.textSecondary,
          textMuted: AppColors.textMuted,
          border: AppColors.border,
          divider: AppColors.divider,
          success: AppColors.success,
          warning: AppColors.warning,
          danger: AppColors.danger,
        ),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colors: const BinLinkColors(
          primary: AppColors.ecoGreen,
          secondary: Colors.white,
          background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
          textPrimary: Colors.white,
          textSecondary: Color(0xFF94A3B8),
          textMuted: Color(0xFF64748B),
          border: Color(0xFF334155),
          divider: Color(0xFF1E293B),
          success: AppColors.success,
          warning: AppColors.warning,
          danger: AppColors.danger,
        ),
      );

  static ThemeData get collector => _build(
        brightness: Brightness.dark,
        colors: const BinLinkColors(
          primary: AppColors.rewardGold,
          secondary: Colors.white,
          background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
          textPrimary: Colors.white,
          textSecondary: Color(0xFF94A3B8),
          textMuted: Color(0xFF64748B),
          border: Color(0xFF334155),
          divider: Color(0xFF1E293B),
          success: AppColors.success,
          warning: AppColors.warning,
          danger: AppColors.danger,
        ),
      );

  static ThemeData _build({
    required Brightness brightness,
    required BinLinkColors colors,
  }) {
    final base = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
    
    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
      ),
      extensions: [
        colors,
        BinLinkTypography(
          h1: AppTypography.h1.copyWith(color: colors.textPrimary),
          h2: AppTypography.h2.copyWith(color: colors.textPrimary),
          h3: AppTypography.h3.copyWith(color: colors.textPrimary),
          bodyLarge: AppTypography.bodyLarge.copyWith(color: colors.textPrimary),
          bodyMedium: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          bodySmall: AppTypography.bodySmall.copyWith(color: colors.textMuted),
          button: AppTypography.button,
          dataLarge: AppTypography.dataLarge.copyWith(color: colors.textPrimary),
          dataMedium: AppTypography.dataMedium.copyWith(color: colors.textPrimary),
          dataSmall: AppTypography.dataSmall.copyWith(color: colors.textSecondary),
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h3.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
