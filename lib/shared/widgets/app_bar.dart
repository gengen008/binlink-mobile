import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Rydr-style app bar for all BinLink screens.
///
/// Rydr pattern (CustomAppBar):
///  - Dark background
///  - Back button inside a rounded square container (leadingBox)
///  - Title centred
///  - Optional trailing action widget
///
/// Rydr bugs fixed:
///  - Used deprecated AppBar.brightness property → replaced with systemOverlayStyle
///  - No const constructor
///  - Hardcoded colours and sizes → all tokens
class AppScaffoldBar extends StatelessWidget implements PreferredSizeWidget {
  const AppScaffoldBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.trailing,
    /// Left-side widget overriding the default back button (e.g. drawer icon).
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.appBarBg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.midnightNavy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: bg,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: AppSpacing.appBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Leading — back button or custom widget
                  if (leading != null)
                    leading!
                  else if (showBack)
                    _BackButton(onBack: onBack)
                  else
                    const SizedBox(width: 45),

                  // Title
                  Expanded(
                    child: centerTitle
                        ? Center(child: _titleWidget())
                        : Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: _titleWidget(),
                          ),
                  ),

                  // Trailing
                  if (trailing != null)
                    trailing!
                  else
                    const SizedBox(width: 45),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleWidget() {
    if (titleWidget != null) return titleWidget!;
    if (title != null) {
      return Text(title!, style: AppTextStyles.appBarTitle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return const SizedBox.shrink();
  }
}

// ── Back button in Rydr-style rounded container ─────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack ?? () => Navigator.maybePop(context),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          // Rydr: Primaryfield fill → BinLink: appBarAction dark tint (NO border — Rydr exact)
          color: AppColors.appBarAction,
          borderRadius: AppRadius.smBR,
        ),
        child: const Icon(
          PhosphorIconsRegular.arrowLeft,
          size: 18,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ── Drawer trigger button (matches Rydr home appbar action) ─────────────────

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        // Rydr: Primaryfield fill (no border)
        decoration: BoxDecoration(
          color: AppColors.steelBlue,
          borderRadius: AppRadius.smBR,
        ),
        child: const Icon(
          PhosphorIconsRegular.list,
          size: 22,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ── Home-style appbar: greeting + subtitle + trailing action ────────────────

/// Two-line title appbar matching Rydr's home_view "Hello, Daniel 👋🏾 / Catch a ride now!"
class AppHomeBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHomeBar({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.onDrawerOpen,
    this.backgroundColor,
  });

  final String greeting;
  final String subtitle;
  final VoidCallback onDrawerOpen;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.appBarBg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: bg,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: AppSpacing.appBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Greeting text — left aligned (Rydr pattern)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: AppTextStyles.appBarTitle),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.appBarSub),
                      ],
                    ),
                  ),
                  // Drawer icon (Rydr: rounded square on the right)
                  DrawerMenuButton(onTap: onDrawerOpen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
