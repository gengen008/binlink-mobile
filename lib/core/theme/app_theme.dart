import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// BINLINK V3 — Premium Theme
///
/// Uber/Bolt Standard: High contrast, bold typography, premium surfaces.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(isCollector: false);
  static ThemeData get collector => _buildTheme(isCollector: true);

  static ThemeData _buildTheme({required bool isCollector}) {
    final primaryColor = isCollector ? AppColors.amber500 : AppColors.primary600;
    final navBg = isCollector ? AppColors.premiumBlack : AppColors.surface;
    final navFg = isCollector ? Colors.white : AppColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: isCollector ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isCollector ? AppColors.premiumBlack : AppColors.background,
      primaryColor: primaryColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: isCollector ? AppColors.amber600 : AppColors.primary700,
        surface: isCollector ? AppColors.premiumBlack : AppColors.surface,
        error: AppColors.error,
        brightness: isCollector ? Brightness.dark : Brightness.light,
      ).copyWith(
        surfaceContainerHighest: isCollector ? AppColors.black : AppColors.background,
      ),

      textTheme: TextTheme(
        displayLarge:   AppTextStyles.display.copyWith(color: navFg),
        displayMedium:  AppTextStyles.h1.copyWith(color: navFg),
        displaySmall:   AppTextStyles.h2.copyWith(color: navFg),
        headlineLarge:  AppTextStyles.h1.copyWith(color: navFg),
        headlineMedium: AppTextStyles.h2.copyWith(color: navFg),
        headlineSmall:  AppTextStyles.h3.copyWith(color: navFg),
        titleLarge:     AppTextStyles.title.copyWith(color: navFg),
        bodyLarge:      AppTextStyles.body.copyWith(color: navFg),
        bodyMedium:     AppTextStyles.body.copyWith(color: navFg),
        bodySmall:      AppTextStyles.caption.copyWith(color: isCollector ? Colors.white70 : AppColors.textSecondary),
        labelLarge:     AppTextStyles.button.copyWith(color: navFg),
        labelSmall:     AppTextStyles.small.copyWith(color: isCollector ? Colors.white60 : AppColors.textMuted),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isCollector ? AppColors.premiumBlack : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: isCollector ? Colors.white : AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: isCollector ? Colors.white : AppColors.textPrimary, 
          size: 24
        ),
        systemOverlayStyle: isCollector ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: isCollector ? const Color(0xFF1E293B) : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBR,
          side: BorderSide(
            color: isCollector ? Colors.white10 : AppColors.border, 
            width: 1
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isCollector ? AppColors.premiumBlack : Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w800,
            color: isCollector ? AppColors.premiumBlack : Colors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isCollector ? Colors.white : AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 58),
          side: BorderSide(
            color: isCollector ? Colors.white24 : AppColors.border, 
            width: 1.5
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppTextStyles.button.copyWith(
            color: isCollector ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isCollector ? const Color(0xFF1E293B) : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: isCollector ? BorderSide.none : const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        hintStyle: AppTextStyles.caption.copyWith(
          color: isCollector ? Colors.white38 : AppColors.textMuted
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isCollector ? AppColors.premiumBlack : AppColors.surface,
        modalBackgroundColor: isCollector ? AppColors.premiumBlack : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        elevation: 20,
        clipBehavior: Clip.antiAlias,
      ),

      dividerTheme: DividerThemeData(
        color: isCollector ? Colors.white10 : AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: primaryColor.withAlpha(isCollector ? 40 : 20),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) 
              ? primaryColor 
              : (isCollector ? Colors.white38 : AppColors.textMuted);
          return AppTextStyles.small.copyWith(color: color, fontWeight: FontWeight.w700);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) 
                ? primaryColor 
                : (isCollector ? Colors.white38 : AppColors.textMuted),
            size: 24,
          );
        }),
      ),
    );
  }

  static ThemeData get dark => collector;
}
