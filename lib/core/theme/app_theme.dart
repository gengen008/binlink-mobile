import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// BinLink Eco — ThemeData
///
/// Single eco-logistics theme shared across household and collector flavors.
/// Design: Plus Jakarta Sans, #16A34A primary, #F8FAFC background.
class AppTheme {
  AppTheme._();

  // All flavors share the same eco theme
  static ThemeData get light          => _eco;
  static ThemeData get dark           => _eco;
  static ThemeData get collectorLight => _eco;
  static ThemeData get collectorDark  => _eco;

  static ThemeData get _eco => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.surface,
    primaryColor: AppColors.primary,

    colorScheme: const ColorScheme.light(
      primary:          AppColors.primary,
      secondary:        AppColors.primaryMid,
      surface:          AppColors.surface,
      error:            AppColors.danger,
      onPrimary:        Colors.white,
      onSecondary:      Colors.white,
      onSurface:        AppColors.secondary,
      onError:          Colors.white,
    ),

    textTheme: TextTheme(
      displayLarge:   AppTextStyles.h1,
      displayMedium:  AppTextStyles.h2,
      displaySmall:   AppTextStyles.h3,
      headlineMedium: AppTextStyles.h4,
      bodyLarge:      AppTextStyles.body,
      bodyMedium:     AppTextStyles.bodyMedium,
      bodySmall:      AppTextStyles.bodySmall,
      labelLarge:     AppTextStyles.button,
      labelMedium:    AppTextStyles.label,
      labelSmall:     AppTextStyles.caption,
    ),

    // ── AppBar — white clean header ────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBarBg,
      foregroundColor: AppColors.secondary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.card,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: AppTextStyles.appBarTitle,
      iconTheme: const IconThemeData(color: AppColors.secondary),
    ),

    // ── Cards — white, 20px radius, light border ───────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBR,
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // ── Input fields — light fill, 20px radius ────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFill,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 14),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: AppRadius.fieldBR,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBR,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBR,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBR,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBR,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),

    // ── Elevated button — green, 20px radius, 56px height ─────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.muted,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonBR,
        ),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),

    // ── Text button ────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
      ),
    ),

    // ── Outlined button ────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonBR,
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
      ),
    ),

    // ── Bottom sheet ───────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      elevation: 0,
    ),

    // ── NavigationBar (Material 3) — used by collector nav ────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      indicatorColor: AppColors.primary.withAlpha(26),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.muted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTextStyles.caption;
      }),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // ── Legacy BottomNavigationBar ─────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // ── Divider ────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── Chip ───────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.fieldFill,
      selectedColor: AppColors.primary.withAlpha(26),
      labelStyle: AppTextStyles.chip,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smBR,
      ),
    ),

    // ── Page transitions — Cupertino slide ────────────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
