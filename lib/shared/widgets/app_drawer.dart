import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'app_dot_separator.dart';

/// Household side drawer — Rydr's RyderDrawer pattern with BinLink wiring.
///
/// Rydr bugs fixed:
///  - Logout never called auth provider → fixed: calls AuthProvider.signOut()
///  - Hardcoded user name → fixed: reads AuthProvider.user
///  - No const constructors → fixed
///  - Social share row included → removed (not needed for BinLink)
///  - Navigator.pushReplacement without clearing state → fixed: signOut() first
///
/// [onTabSwitch] — optional callback to switch the home screen tab index.
/// Pass this when the drawer is inside [HouseholdHomeScreen] so tapping
/// "History" switches the IndexedStack rather than pushing a new route.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onTabSwitch});

  /// If provided, drawer items that map to home tabs call this instead of Navigator.
  final void Function(int tab)? onTabSwitch;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.fullName ?? 'BinLink User';
    final initials = Fmt.initials(name);
    final role = user?.role ?? 'HOUSEHOLD';

    return Container(
      // Rydr: width = MediaQuery.width / 1.5, rounded right side
      width: MediaQuery.sizeOf(context).width / 1.5,
      margin: const EdgeInsets.only(right: 30),
      child: ClipRRect(
        borderRadius: AppRadius.drawerBR,
        child: Material(
          color: AppColors.drawerBg,
          child: Column(
            children: [
              // ── Profile header ─────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.steelBlue.withAlpha(80),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.h2.copyWith(fontSize: 24),
                          ),
                        ),
                      ),
                      const YGap(AppSpacing.s12),
                      Text(
                        name,
                        style: AppTextStyles.drawerTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const YGap(AppSpacing.s4),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(30),
                          borderRadius: AppRadius.fullBR,
                          border: Border.all(color: AppColors.steelBlue.withAlpha(80)),
                        ),
                        child: Text(
                          role == 'COLLECTOR' ? 'Collector' : 'Household',
                          style: AppTextStyles.chip.copyWith(
                            color: AppColors.skyBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const YGap(AppSpacing.s14),
                      // Edit profile button (Rydr: rounded dark button)
                      GestureDetector(
                        onTap: () => _navigate(context, '/edit-profile'),
                        child: Container(
                          height: 34,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.steelBlue,
                            borderRadius: AppRadius.smBR,
                          ),
                          child: const Center(
                            child: Text('Edit Profile', style: AppTextStyles.buttonSm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const AppDotSeparator(padding: EdgeInsets.symmetric(horizontal: 16)),
              const YGap(AppSpacing.s10),

              // ── Menu items ─────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  children: [
                    _DrawerItem(
                      icon: PhosphorIconsRegular.house,
                      label: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        onTabSwitch?.call(0);
                      },
                    ),
                    _DrawerItem(
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      label: 'History',
                      onTap: () {
                        Navigator.pop(context);
                        onTabSwitch?.call(1);
                      },
                    ),
                    _DrawerItem(
                      icon: PhosphorIconsRegular.bell,
                      label: 'Notifications',
                      onTap: () => _navigate(context, '/notifications'),
                    ),
                    _DrawerItem(
                      icon: PhosphorIconsRegular.wallet,
                      label: 'Payments & Plans',
                      onTap: () => _navigate(context, '/payment'),
                    ),
                    _DrawerItem(
                      icon: PhosphorIconsRegular.lifebuoy,
                      label: 'Help & Support',
                      onTap: () => _navigate(context, '/help'),
                    ),
                    _DrawerItem(
                      icon: PhosphorIconsRegular.shieldCheck,
                      label: 'Privacy Policy',
                      onTap: () => _navigate(context, '/privacy'),
                    ),
                  ],
                ),
              ),

              // ── Footer ─────────────────────────────────────────────────
              const AppDotSeparator(padding: EdgeInsets.symmetric(horizontal: 16)),
              const YGap(AppSpacing.s10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: GestureDetector(
                  onTap: () => _handleLogout(context, auth),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(20),
                      borderRadius: AppRadius.smBR,
                      border: Border.all(color: AppColors.danger.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.signOut,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const XGap(AppSpacing.s8),
                        Text(
                          'Log Out',
                          style: AppTextStyles.buttonSecondary.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SafeArea(
                top: false,
                child: YGap(AppSpacing.s20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Push a named or implicit route, closing drawer first.
  void _navigate(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, route);
  }

  /// Rydr bug fix: Rydr never called auth provider signOut on logout.
  /// BinLink fix: call signOut() which invalidates server-side token,
  /// clears SecureStorage, disconnects socket, then navigate to login.
  Future<void> _handleLogout(BuildContext context, AuthProvider auth) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context); // close drawer immediately
    await auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}

// ── Drawer list tile ──────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.steelBlue.withAlpha(20),
          borderRadius: AppRadius.xsBR,
        ),
        child: Icon(icon, color: AppColors.skyBlue, size: 17),
      ),
      title: Text(label, style: AppTextStyles.drawerItem),
    );
  }
}
