import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      backgroundColor: AppColors.background,
      appBar: const AppScaffoldBar(
        title: 'Account',
        showBack: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          children: [
            // ── Profile Header ──
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.background,
                            backgroundImage: user?.profilePhoto != null 
                                ? NetworkImage(user!.profilePhoto!) 
                                : null,
                            child: user?.profilePhoto == null 
                                ? Text(
                                    Fmt.initials(user?.fullName ?? 'U'),
                                    style: AppTextStyles.h1.copyWith(color: AppColors.primary900, fontSize: 24),
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.circleCheck, color: AppColors.success, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'BinLink User', style: AppTextStyles.h2.copyWith(fontSize: 24)),
                          Text(user?.email ?? 'user@binlink.eco', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    _RoundActionBtn(
                      icon: LucideIcons.pencil,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    ),
                  ],
                ),
              ),
            ),

            // ── Eco points Card (Revolut/Stripe Style) ──
            FadeInUp(
              child: _PremiumEcoCard(points: user?.ecoPoints ?? 0),
            ),

            const SizedBox(height: 32),

            // ── Analytics Section ──
            const _AnalyticsSection(),

            const SizedBox(height: 32),

            // ── Menu List (Grouped) ──
            _MenuSection(
              title: "General",
              items: [
                _MenuItemV4(
                  icon: LucideIcons.mapPin, 
                  label: 'Saved Addresses', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen()))
                ),
                _MenuItemV4(
                  icon: LucideIcons.calendar, 
                  label: 'Subscriptions', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()))
                ),
                _MenuItemV4(
                  icon: LucideIcons.bell, 
                  label: 'Notifications', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
                ),
                _MenuItemV4(
                  icon: LucideIcons.star, 
                  label: 'Rate BinLink', 
                  onTap: () {
                    // TODO: Implement In-App Review
                  }
                ),
              ],
            ),

            _MenuSection(
              title: "Security & Legal",
              items: [
                _MenuItemV4(
                  icon: LucideIcons.circleHelp, 
                  label: 'Help & Support', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))
                ),
                _MenuItemV4(
                  icon: LucideIcons.shieldCheck, 
                  label: 'Privacy Policy', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))
                ),
                _MenuItemV4(
                  icon: LucideIcons.fileText, 
                  label: 'Terms of Service', 
                  onTap: () {
                    // TODO: Push Terms Screen
                  }
                ),
              ],
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumEcoCard extends StatelessWidget {
  const _PremiumEcoCard({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary900,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary900.withAlpha(50),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
        image: const DecorationImage(
          image: AssetImage(AppAssets.bin3d),
          alignment: Alignment.centerRight,
          opacity: 0.1,
          // Removed scale: 0.5 as it breaks scaling on devices.
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ECO POINTS", style: AppTextStyles.small.copyWith(color: Colors.white60, letterSpacing: 2)),
              const Icon(LucideIcons.leaf, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text("$points", style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 40)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "Top 10% in Accra",
              style: AppTextStyles.small.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final recycledKg = user?.totalKgRecycled ?? 0.0;
    final co2Saved = recycledKg * 0.6; // Approximation: 0.6kg CO2 per kg recycled

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("IMPACT ANALYTICS", style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(
                label: "Recycled",
                value: "${recycledKg.toStringAsFixed(1)} kg",
                icon: LucideIcons.recycle,
                color: AppColors.success,
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: "Saved CO2",
                value: "${co2Saved.toStringAsFixed(1)} kg",
                icon: LucideIcons.cloudRain,
                color: AppColors.primary500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(value, style: AppTextStyles.h2.copyWith(fontSize: 20)),
            Text(label, style: AppTextStyles.caption),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemV4 extends StatelessWidget {
  const _MenuItemV4({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, size: 22, color: AppColors.textPrimary),
      title: Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
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
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
