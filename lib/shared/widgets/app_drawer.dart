import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/household/screens/edit_profile_screen.dart';

/// Household side drawer.
///
/// [onTabSwitch] — optional callback to switch the home screen tab index.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onTabSwitch, this.currentIndex = 0});

  final void Function(int tab)? onTabSwitch;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.fullName ?? 'BinLink User';
    final initials = Fmt.initials(name);

    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      margin: const EdgeInsets.only(right: 30),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Profile header ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: const Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary300.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.h1.copyWith(color: AppColors.primary900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: AppTextStyles.h2),
                      Text(user?.email ?? '', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        },
                        child: Container(
                          height: 44, // 44px min touch target
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.pencil, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Edit Profile', style: AppTextStyles.small.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Menu items ─────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _DrawerListTile(
                        icon: LucideIcons.house,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () {
                          Navigator.pop(context);
                          onTabSwitch?.call(0);
                        },
                      ),
                      _DrawerListTile(
                        icon: LucideIcons.history,
                        label: 'Pickup History',
                        isActive: currentIndex == 1,
                        onTap: () {
                          Navigator.pop(context);
                          onTabSwitch?.call(1);
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.divider),
                      ),
                      _DrawerListTile(
                        icon: LucideIcons.bell,
                        label: 'Notifications',
                        onTap: () => _navigate(context, '/notifications'),
                      ),
                      _DrawerListTile(
                        icon: LucideIcons.creditCard,
                        label: 'Payments & Plans',
                        onTap: () => _navigate(context, '/payment'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.divider),
                      ),
                      _DrawerListTile(
                        icon: LucideIcons.circleHelp,
                        label: 'Help & Support',
                        onTap: () => _navigate(context, '/help'),
                      ),
                      _DrawerListTile(
                        icon: LucideIcons.shieldCheck,
                        label: 'Privacy Policy',
                        onTap: () => _navigate(context, '/privacy'),
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _DrawerListTile(
                    icon: LucideIcons.logOut,
                    label: 'Log out',
                    isDestructive: true,
                    onTap: () => _handleLogout(context, auth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider auth) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    await auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}

class _DrawerListTile extends StatelessWidget {
  const _DrawerListTile({
    required this.icon,
    required this.label, 
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive 
        ? AppColors.error 
        : (isActive ? AppColors.primary : AppColors.textPrimary);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label, 
          style: AppTextStyles.body.copyWith(
            color: color, 
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600
          )
        ),
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
