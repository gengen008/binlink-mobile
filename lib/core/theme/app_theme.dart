import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // Household app — steelBlue primary (default)
  static ThemeData get dark => _build(
    primary: AppColors.steelBlue,
    secondary: AppColors.skyBlue,
  );

  // Collector app — amber primary (Bolt Driver / warm driver-app convention)
  static ThemeData get collectorDark => _build(
    primary: AppColors.warning,
    secondary: const Color(0xFFFBBF24),
  );

  static ThemeData _build({required Color primary, required Color secondary}) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.midnightNavy,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      fontFamily: 'PlusJakartaSans',
      textTheme: const TextTheme(
        displayLarge:  AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall:  AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        bodyLarge:    AppTextStyles.body,
        bodyMedium:   AppTextStyles.label,
        bodySmall:    AppTextStyles.caption,
        labelLarge:   AppTextStyles.button,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.midnightNavy,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.midnightNavy,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.h3,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
        labelStyle: AppTextStyles.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.deepOcean,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
