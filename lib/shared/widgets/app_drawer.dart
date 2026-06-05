// Rydr RyderDrawer — literal transplant.
//
// Rydr source: rydr_drawer.dart
//   Container(w/1.5, margin.right:30) > ClipRRect(only topRight/bottomRight:10)
//   > Drawer > Padding(top:70) > Column(mainAxisAlignment:end, [
//     Row(center, profile_column),
//     YMargin(10), DrawerDots, YMargin(10),
//     Padding(left:25, Column([DrawerListTile...])),
//     Spacer(),
//     DrawerDots, YMargin(10),
//     Text("Share on:", montserrat, 10, w400, Primarydark),
//     YMargin(10),
//     Row(center, [Container(25×25,whatsapp), XMargin(5), Container(25×25,twitter), XMargin(5), Container(25×25,facebook)]),
//     YMargin(10),
//     Padding(h:50, Container(h:40,w:137,Primaryred,br:8,"Log out").ripple(signOut)),
//     YMargin(10),
//     Spacer()
//   ])
//
// BinLink replacements only:
//   - driver image → initials container (110×110 circle)
//   - Primarydark → AppColors.midnightNavy
//   - Primaryfield → AppColors.border
//   - Primaryred → AppColors.danger
//   - social image assets → Phosphor brand icons (same 25×25 dimensions)
//   - Rydr signOut() → AuthProvider.signOut() + Navigator.pushNamedAndRemoveUntil

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'app_dot_separator.dart';

/// Household side drawer — LITERAL Rydr RyderDrawer widget-tree transplant.
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
      // Rydr: width = MediaQuery.of(context).size.width / 1.5, margin.right:30
      width: MediaQuery.sizeOf(context).width / 1.5,
      margin: const EdgeInsets.only(right: 30),
      child: ClipRRect(
        // Rydr: only(topRight:10, bottomRight:10)
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        // Rydr: Drawer widget — white background (Rydr default)
        child: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Padding(
              // Rydr: Padding(top: 70)
              padding: const EdgeInsets.only(top: 70),
              child: Column(
                // Rydr: mainAxisAlignment: end — with Spacer() widgets below
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  // ── Profile header ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          // Rydr: Padding(h:30, Container(Image 110×110, driverpic))
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
                          // Rydr: Text(name, montserrat, 15, w600, Primarydark)
                          Text(name, style: AppTextStyles.drawerTitle,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 15),
                          // Rydr: Padding(h:50, Container(h:33, w:125, Primarydark, br:8, "Edit Profile"))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: GestureDetector(
                              onTap: () => _navigate(context, '/edit-profile'),
                              child: Container(
                                height: 33,
                                width: 125,
                                decoration: BoxDecoration(
                                  color: AppColors.midnightNavy,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
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
                  // Rydr: DrawerDots(dashColor:Primaryfield, dashHeight:1.0, dashWidth:2.0)
                  const AppDotSeparator(
                    dashWidth: 2.0,
                    dashHeight: 1.0,
                    color: AppColors.border,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  const SizedBox(height: 10),

                  // ── Menu items ─────────────────────────────────────────────
                  // Rydr: Padding(left:25, Column([DrawerListTile...]))
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
                          label: 'Trip History',
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

                  // Rydr: DrawerDots(dashColor:Primaryfield, dashHeight:1.0, dashWidth:2.0)
                  const AppDotSeparator(
                    dashWidth: 2.0,
                    dashHeight: 1.0,
                    color: AppColors.border,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  const SizedBox(height: 10),

                  // Rydr: Text("Share on:", montserrat, 10, w400, Primarydark)
                  Text(
                    'Share on:',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rydr: Row(center, [Container(25×25,whatsapp), XMargin(5), Container(25×25,twitter), XMargin(5), Container(25×25,facebook)])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(PhosphorIconsFill.whatsappLogo,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DA1F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(PhosphorIconsFill.twitterLogo,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(PhosphorIconsFill.facebookLogo,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rydr: Padding(h:50, Container(h:40,w:137,Primaryred,br:8,"Log out").ripple(signOut))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: GestureDetector(
                      onTap: () => _handleLogout(context, auth),
                      child: Container(
                        height: 40,
                        width: 137,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Log out',
                              style: AppTextStyles.buttonSecondary.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
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

// ── Drawer list tile — LITERAL Rydr DrawerListTile transplant ─────────────────
//
// Rydr: ListTile(onTap: onPressed, title: Text(title, montserrat, 12, w600, Primarydark))

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
