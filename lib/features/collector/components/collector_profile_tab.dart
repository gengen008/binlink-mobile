import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/collector_provider.dart';
import '../screens/vehicle_details_screen.dart';
import '../screens/collector_edit_profile_screen.dart';
import '../screens/collector_help_screen.dart';
import '../screens/collector_privacy_screen.dart';
import '../screens/collector_notifications_screen.dart';
import '../../../shared/widgets/app_bar.dart';

class CollectorProfileTab extends StatelessWidget {
  const CollectorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final collectorProv = context.watch<CollectorProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const AppScaffoldBar(
        title: 'Driver Profile',
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
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.premiumBlack,
                      child: Text(
                        Fmt.initials(user?.fullName ?? 'C'),
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user?.fullName ?? 'Collector', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                              const SizedBox(width: 8),
                              Image.asset(AppAssets.verifiedBadge, width: 18, height: 18),
                            ],
                          ),
                          Text(user?.email ?? '', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    _RoundActionBtn(
                      icon: LucideIcons.pencil,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorEditProfileScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Earnings Card ──
            FadeInUp(
              child: _EarningsCardV4(amount: collectorProv.totalEarnings),
            ),

            const SizedBox(height: 32),

            // ── Collector Stats ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CollectorStatTile(label: 'Total Jobs', value: '${user?.totalPickups ?? 0}', icon: LucideIcons.circleCheck),
                      const SizedBox(width: 16),
                      _CollectorStatTile(label: 'Rating', value: '${user?.rating ?? 5.0} ★', icon: LucideIcons.star),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _CollectorStatTile(label: 'Total kg', value: '${Fmt.toDouble(user?.totalKgRecycled).toInt()}', icon: LucideIcons.leaf),
                      const SizedBox(width: 16),
                      _CollectorStatTile(label: 'Eco Points', value: '${user?.ecoPoints ?? 0}', icon: LucideIcons.zap),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Driver Menu ──
            _DriverMenuSection(
              title: "Vehicle & Fleet",
              items: [
                _DriverMenuItem(icon: LucideIcons.truck, label: 'Vehicle Details', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleDetailsScreen()))),
                _DriverMenuItem(icon: LucideIcons.bell, label: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorNotificationsScreen()))),
              ],
            ),

            _DriverMenuSection(
              title: "Support",
              items: [
                _DriverMenuItem(icon: LucideIcons.circleHelp, label: 'Help Center', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorHelpScreen()))),
                _DriverMenuItem(icon: LucideIcons.shieldCheck, label: 'Legal & Privacy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorPrivacyScreen()))),
              ],
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.premiumBlack,
                      title: Text('Sign Out', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                      content: Text('Are you sure you want to sign out?', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Sign Out', style: AppTextStyles.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    auth.signOut();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text('Sign Out', style: AppTextStyles.button.copyWith(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCardV4 extends StatelessWidget {
  const _EarningsCardV4({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.premiumBlack,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
            child: Icon(LucideIcons.landmark, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Earnings", style: AppTextStyles.label.copyWith(color: Colors.white54)),
                Text(Fmt.currency(amount), style: AppTextStyles.h1.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 24),
        ],
      ),
    );
  }
}

class _CollectorStatTile extends StatelessWidget {
  const _CollectorStatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.premiumBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 16),
            Text(value, style: AppTextStyles.h2.copyWith(color: Colors.white)),
            Text(label, style: AppTextStyles.label.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _DriverMenuSection extends StatelessWidget {
  const _DriverMenuSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: Colors.white38)),
        ),
        ...items,
      ],
    );
  }
}

class _DriverMenuItem extends StatelessWidget {
  _DriverMenuItem({required this.icon, required this.label, required this.onTap});
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
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(label, style: AppTextStyles.h4.copyWith(color: Colors.white)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white24),
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
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}
