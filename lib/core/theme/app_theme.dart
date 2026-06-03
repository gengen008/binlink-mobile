import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // Household app — steelBlue primary (dark)
  static ThemeData get dark => _build(
    primary: AppColors.steelBlue,
    secondary: AppColors.skyBlue,
    isDark: true,
  );

  // Household app — steelBlue primary (light)
  static ThemeData get light => _build(
    primary: AppColors.steelBlue,
    secondary: AppColors.skyBlue,
    isDark: false,
  );

  // Collector app — amber primary (dark)
  static ThemeData get collectorDark => _build(
    primary: AppColors.warning,
    secondary: const Color(0xFFFBBF24),
    isDark: true,
  );

  // Collector app — amber primary (light)
  static ThemeData get collectorLight => _build(
    primary: AppColors.warning,
    secondary: const Color(0xFFFBBF24),
    isDark: false,
  );

  static ThemeData _build({
    required Color primary,
    required Color secondary,
    bool isDark = true,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final scaffoldBg = isDark ? AppColors.midnightNavy : const Color(0xFFF5F7FA);
    final surface = isDark ? AppColors.surface : Colors.white;
    final cardColor = isDark ? AppColors.card : Colors.white;
    final border = isDark ? AppColors.border : const Color(0xFFE0E6EF);
    final muted = isDark ? AppColors.muted : const Color(0xFF8A9BB5);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primary,
              secondary: secondary,
              surface: AppColors.surface,
              error: AppColors.danger,
            )
          : ColorScheme.light(
              primary: primary,
              secondary: secondary,
              surface: surface,
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
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.midnightNavy : const Color(0xFFFFFFFF),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? AppColors.midnightNavy : const Color(0xFFFFFFFF),
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.h3,
        iconTheme: IconThemeData(color: isDark ? AppColors.white : AppColors.midnightNavy),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: AppTextStyles.body.copyWith(color: muted),
        labelStyle: AppTextStyles.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
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
        backgroundColor: isDark ? AppColors.deepOcean : Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
