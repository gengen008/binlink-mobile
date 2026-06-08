import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../screens/saved_addresses_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/help_screen.dart';
import '../screens/privacy_screen.dart';
import '../../../shared/widgets/app_bar.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(
        title: 'Profile',
        showBack: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // ── Profile Header ──
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surface,
                          child: Text(
                            Fmt.initials(user?.fullName ?? 'U'),
                            style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Image.asset(AppAssets.verifiedBadge, width: 20, height: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'BinLink User', style: AppTextStyles.h2),
                          Text(user?.email ?? '', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    _RoundActionBtn(
                      icon: PhosphorIconsFill.pencilSimple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── 3D Wallet Card ──
            FadeInUp(
              child: _WalletCardV4(points: user?.ecoPoints ?? 0),
            ),

            const SizedBox(height: 32),

            // ── Stats Grid ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _StatTileV4(label: 'Pickups', value: '${user?.totalPickups ?? 0}', icon: PhosphorIconsFill.truck),
                  const SizedBox(width: 16),
                  _StatTileV4(label: 'Recycled', value: '${user?.totalKgRecycled.toInt() ?? 0}kg', icon: PhosphorIconsFill.leaf),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Menu List ──
            _MenuSection(
              title: "Preferences",
              items: [
                _MenuItemV4(icon: PhosphorIconsFill.mapPin, label: 'Saved Addresses', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen()))),
                _MenuItemV4(icon: PhosphorIconsFill.calendarBlank, label: 'Subscriptions', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()))),
                _MenuItemV4(icon: PhosphorIconsFill.bell, label: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              ],
            ),

            _MenuSection(
              title: "Support",
              items: [
                _MenuItemV4(icon: PhosphorIconsFill.question, label: 'Help & Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
                _MenuItemV4(icon: PhosphorIconsFill.shieldCheck, label: 'Privacy Policy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
              ],
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextButton(
                onPressed: () => auth.signOut(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text('Log Out', style: AppTextStyles.h4.copyWith(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCardV4 extends StatelessWidget {
  const _WalletCardV4({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Image.asset(AppAssets.wallet3d, width: 60, height: 60),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Eco Points Balance", style: AppTextStyles.label.copyWith(color: Colors.white70)),
                Text("$points Points", style: AppTextStyles.h1.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const Icon(PhosphorIconsRegular.caretRight, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _StatTileV4 extends StatelessWidget {
  const _StatTileV4({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 16),
            Text(value, style: AppTextStyles.h2),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ),
        ...items,
      ],
    );
  }
}

class _MenuItemV4 extends StatelessWidget {
  _MenuItemV4({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
      title: Text(label, style: AppTextStyles.h4),
      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 18, color: AppColors.textMuted),
    );
  }
}

class _RoundActionBtn extends StatelessWidget {
  const _RoundActionBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}
