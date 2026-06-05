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
  static ThemeData get dark  => _build(primary: AppColors.steelBlue,  secondary: AppColors.skyBlue);
  static ThemeData get light => _build(primary: AppColors.steelBlue,  secondary: AppColors.skyBlue);

  // ── Collector app themes ───────────────────────────────────────────────────
  static ThemeData get collectorDark  => _build(primary: AppColors.warning, secondary: const Color(0xFFFBBF24));
  static ThemeData get collectorLight => _build(primary: AppColors.warning, secondary: const Color(0xFFFBBF24));

  // ── Builder ────────────────────────────────────────────────────────────────
  static ThemeData _build({
    required Color primary,
    required Color secondary,
  }) {
    // Rydr light theme — white scaffold throughout regardless of brightness param
    const brightness  = Brightness.light;
    const scaffoldBg  = Colors.white;
    const surfaceCol  = Colors.white;
    const cardCol     = Color(0xFFDCE1DE);
    const borderCol   = Color(0xFFDCE1DE);
    const mutedCol    = AppColors.muted;
    const fieldFill   = Color(0xFFDCE1DE);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,

      colorScheme: ColorScheme.light(
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

      // ── AppBar — dark header (70px height) ────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBg,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(
          color: AppColors.white,
        ),
      ),

      // ── Cards — Rydr: 10-15px radius, flat ────────────────────────────────
      cardTheme: CardThemeData(
        color: cardCol,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBR,
          side: const BorderSide(color: borderCol),
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
          borderSide: const BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: const BorderSide(color: borderCol),
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
        elevation: 0,
      ),

      // ── Bottom nav bar ─────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: mutedCol,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: borderCol, thickness: 1),

      // ── Page transitions — Cupertino slide (Rydr uses default push) ────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
