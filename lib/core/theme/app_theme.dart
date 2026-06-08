import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// BinLink "V4" Premium Theme
///
/// Designed to meet Uber/Bolt standards. High contrast, bold typography,
/// and subtle depth (shadows) to avoid the "AI-generated" flat look.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,

    colorScheme: ColorScheme.light(
      primary:          AppColors.primary,
      secondary:        AppColors.secondary,
      surface:          AppColors.background,
      error:            AppColors.danger,
      onPrimary:        Colors.white,
      onSurface:        AppColors.textPrimary,
    ),

    textTheme: TextTheme(
      displayLarge:   AppTextStyles.h1,
      displayMedium:  AppTextStyles.h2,
      displaySmall:   AppTextStyles.h3,
      bodyLarge:      AppTextStyles.body,
      bodyMedium:     AppTextStyles.bodySmall,
      labelSmall:     AppTextStyles.label,
    ),

    // ── Components ───────────────────────────────────────────────────────────

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false, // Uber/Bolt style: left-aligned often
      titleTextStyle: AppTextStyles.appBarTitle,
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBR,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.primary.withAlpha(80),
        minimumSize: const Size(double.infinity, 58), // Taller buttons
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        textStyle: AppTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: BorderSide(color: AppColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: BorderSide(color: AppColors.danger, width: 1.0),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.background,
      modalBackgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 16,
      shadowColor: Colors.black.withAlpha(100),
    ),
  );

  static ThemeData get dark => light.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    appBarTheme: light.appBarTheme.copyWith(
      backgroundColor: AppColors.black,
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: light.cardTheme.copyWith(
      color: AppColors.premiumBlack,
    ),
  );
}
