import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// BinLink Eco — ThemeData
///
/// Disciplined, operational theme inspired by Bolt/Uber.
/// Primary: BinLink Green (#16A34A)
/// Surface: White/Grey neutral
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme();
  static ThemeData get dark  => _buildTheme(); // Currently single theme

  static ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.surface,
    primaryColor: AppColors.primary,

    colorScheme: const ColorScheme.light(
      primary:          AppColors.primary,
      secondary:        AppColors.secondary,
      surface:          AppColors.surface,
      error:            AppColors.danger,
      onPrimary:        Colors.white,
      onSecondary:      Colors.white,
      onSurface:        AppColors.secondary,
      onError:          Colors.white,
    ),

    textTheme: TextTheme(
      displayLarge:   AppTextStyles.display,
      displayMedium:  AppTextStyles.h2,
      displaySmall:   AppTextStyles.h3,
      headlineMedium: AppTextStyles.h4,
      bodyLarge:      AppTextStyles.body,
      bodyMedium:     AppTextStyles.bodyMedium,
      bodySmall:      AppTextStyles.bodySmall,
      labelLarge:     AppTextStyles.button,
      labelMedium:    AppTextStyles.meta,
      labelSmall:     AppTextStyles.caption,
    ),

    // ── AppBar — stark white header ────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBarBg,
      foregroundColor: AppColors.secondary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: AppTextStyles.appBarTitle,
      iconTheme: const IconThemeData(color: AppColors.secondary, size: 22),
    ),

    // ── Cards — flat white, subtle border, 12px radius ─────────────────────
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBR,
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // ── Input fields — neutral grey fill, 12px radius ──────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFill,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.fieldHint, fontSize: 14),
      labelStyle: AppTextStyles.meta.copyWith(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBR,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // ── Buttons — high-contrast, 12px radius ───────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textMuted,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
      ),
    ),

    // ── Bottom sheet — 20px top radius ─────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      elevation: 0,
    ),

    // ── Navigation Bar ─────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.primary.withAlpha(20),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700);
        }
        return AppTextStyles.caption;
      }),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
