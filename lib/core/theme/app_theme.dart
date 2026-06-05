import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// BinLink AppTheme — Rydr design language on BinLink dark palette.
///
/// Field radius aligned to Rydr (9px), sheet radius (20px top-only),
/// card radius (12px), button radius (8px), appbar height (70px).
class AppTheme {
  AppTheme._();

  // ── Household app themes ───────────────────────────────────────────────────
  static ThemeData get dark  => _build(primary: AppColors.steelBlue,  secondary: AppColors.skyBlue, isDark: true);
  static ThemeData get light => _build(primary: AppColors.steelBlue,  secondary: AppColors.skyBlue, isDark: false);

  // ── Collector app themes ───────────────────────────────────────────────────
  static ThemeData get collectorDark  => _build(primary: AppColors.warning, secondary: const Color(0xFFFBBF24), isDark: true);
  static ThemeData get collectorLight => _build(primary: AppColors.warning, secondary: const Color(0xFFFBBF24), isDark: false);

  // ── Builder ────────────────────────────────────────────────────────────────
  static ThemeData _build({
    required Color primary,
    required Color secondary,
    bool isDark = true,
  }) {
    final brightness  = isDark ? Brightness.dark : Brightness.light;
    final scaffoldBg  = isDark ? AppColors.midnightNavy : const Color(0xFFF5F7FA);
    final surfaceCol  = isDark ? AppColors.surface       : Colors.white;
    final cardCol     = isDark ? AppColors.card          : Colors.white;
    final borderCol   = isDark ? AppColors.border        : const Color(0xFFE0E6EF);
    final mutedCol    = isDark ? AppColors.muted         : const Color(0xFF8A9BB5);
    final fieldFill   = isDark ? AppColors.fieldFill     : const Color(0xFFF0F4F8);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,

      colorScheme: isDark
          ? ColorScheme.dark(
              primary:   primary,
              secondary: secondary,
              surface:   AppColors.surface,
              error:     AppColors.danger,
            )
          : ColorScheme.light(
              primary:   primary,
              secondary: secondary,
              surface:   surfaceCol,
              error:     AppColors.danger,
            ),

      fontFamily: 'PlusJakartaSans',

      textTheme: const TextTheme(
        displayLarge:   AppTextStyles.h1,
        displayMedium:  AppTextStyles.h2,
        displaySmall:   AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        bodyLarge:      AppTextStyles.body,
        bodyMedium:     AppTextStyles.label,
        bodySmall:      AppTextStyles.caption,
        labelLarge:     AppTextStyles.button,
      ),

      // ── AppBar — matches Rydr's dark header (70px height) ─────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.appBarBg : Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? AppColors.midnightNavy : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.white : AppColors.midnightNavy,
        ),
      ),

      // ── Cards — Rydr: 10-15px radius, flat ────────────────────────────────
      cardTheme: CardThemeData(
        color: cardCol,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBR,
          side: BorderSide(color: borderCol),
        ),
      ),

      // ── Input fields — Rydr: 9px radius, field fill background ────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        hintStyle: AppTextStyles.body.copyWith(color: mutedCol),
        labelStyle: AppTextStyles.label,
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ── Buttons — Rydr: 8px radius, 50-52px height ────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smBR,
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),

      // ── Bottom sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.sheetBg : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
        elevation: 0,
      ),

      // ── Bottom nav bar ─────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.navBarBg : Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: mutedCol,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(color: borderCol, thickness: 1),

      // ── Page transitions — Cupertino slide (Rydr uses default push) ────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
