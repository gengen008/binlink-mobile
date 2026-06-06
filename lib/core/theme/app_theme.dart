import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// BinLink "Base" Platform Theme
///
/// World-class operational aesthetic. Stark high-contrast surfaces,
/// purely functional componentry, and 16px mobility radius standards.
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
      displayLarge:   AppTextStyles.display,
      titleLarge:     AppTextStyles.title,
      titleMedium:    AppTextStyles.section,
      bodyLarge:      AppTextStyles.body,
      bodyMedium:     AppTextStyles.bodyMedium,
      labelSmall:     AppTextStyles.caption,
    ),

    // ── Components ───────────────────────────────────────────────────────────

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.appBarTitle,
      iconTheme: IconThemeData(color: AppColors.primary, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      color: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBR,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        textStyle: AppTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      elevation: 0,
    ),
  );

  static ThemeData get dark => light.copyWith(brightness: Brightness.dark);
}
