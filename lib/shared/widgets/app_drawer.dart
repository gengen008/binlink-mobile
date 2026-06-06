import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'app_dot_separator.dart';

/// Household side drawer.
///
/// [onTabSwitch] — optional callback to switch the home screen tab index.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onTabSwitch});

  final void Function(int tab)? onTabSwitch;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.fullName ?? 'BinLink User';
    final initials = Fmt.initials(name);

    return Container(
      width: MediaQuery.sizeOf(context).width / 1.5,
      margin: const EdgeInsets.only(right: 30),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        child: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  // ── Profile header ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(name, style: AppTextStyles.drawerTitle,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: GestureDetector(
                              onTap: () => _navigate(context, '/edit-profile'),
                              child: Container(
                                height: 33,
                                width: 125,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Edit Profile',
                                        style: AppTextStyles.buttonSm),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const AppDotSeparator(
                    dashWidth: 2.0,
                    dashHeight: 1.0,
                    color: AppColors.border,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  const SizedBox(height: 10),

                  // ── Menu items ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: Column(
                      children: [
                        _DrawerListTile(
                          label: 'Home',
                          onTap: () {
                            Navigator.pop(context);
                            onTabSwitch?.call(0);
                          },
                        ),
                        _DrawerListTile(
                          label: 'Pickup History',
                          onTap: () {
                            Navigator.pop(context);
                            onTabSwitch?.call(1);
                          },
                        ),
                        _DrawerListTile(
                          label: 'Notifications',
                          onTap: () => _navigate(context, '/notifications'),
                        ),
                        _DrawerListTile(
                          label: 'Payments & Plans',
                          onTap: () => _navigate(context, '/payment'),
                        ),
                        _DrawerListTile(
                          label: 'Help & Support',
                          onTap: () => _navigate(context, '/help'),
                        ),
                        _DrawerListTile(
                          label: 'Privacy Policy',
                          onTap: () => _navigate(context, '/privacy'),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Divider(height: 24),
                  _DrawerListTile(
                    label: 'Log out',
                    onTap: () => _handleLogout(context, auth),
                  ),
                  const SizedBox(height: 20),
                  const Spacer(),
                ],
              ),
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

//

class _DrawerListTile extends StatelessWidget {
  const _DrawerListTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: AppTextStyles.drawerItem),
    );
  }
}
