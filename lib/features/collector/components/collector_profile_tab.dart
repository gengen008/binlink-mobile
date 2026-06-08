import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
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
                      icon: PhosphorIconsFill.pencilSimple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorEditProfileScreen())),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Earnings Card ──
            FadeInUp(
              child: _EarningsCardV4(amount: Fmt.toDouble(user?.totalEarned ?? 0)),
            ),

            const SizedBox(height: 32),

            // ── Collector Stats ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _CollectorStatTile(label: 'Total Jobs', value: '${user?.totalPickups ?? 0}', icon: PhosphorIconsFill.checkCircle),
                  const SizedBox(width: 16),
                  _CollectorStatTile(label: 'Rating', value: '${user?.rating ?? 5.0} ★', icon: PhosphorIconsFill.star),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Driver Menu ──
            _DriverMenuSection(
              title: "Vehicle & Fleet",
              items: [
                _DriverMenuItem(icon: PhosphorIconsFill.truck, label: 'Vehicle Details', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleDetailsScreen()))),
                _DriverMenuItem(icon: PhosphorIconsFill.bell, label: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorNotificationsScreen()))),
              ],
            ),

            _DriverMenuSection(
              title: "Support",
              items: [
                _DriverMenuItem(icon: PhosphorIconsFill.question, label: 'Help Center', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorHelpScreen()))),
                _DriverMenuItem(icon: PhosphorIconsFill.shieldCheck, label: 'Legal & Privacy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorPrivacyScreen()))),
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
                child: Text('Sign Out', style: AppTextStyles.h4.copyWith(color: AppColors.danger)),
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
            child: Icon(PhosphorIconsFill.bank, color: AppColors.primary, size: 28),
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
          const Icon(PhosphorIconsRegular.caretRight, color: Colors.white24, size: 24),
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
        decoration: BoxDecoration(color: AppColors.premiumBlack, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: Colors.white70),
      ),
      title: Text(label, style: AppTextStyles.h4.copyWith(color: Colors.white)),
      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 18, color: Colors.white24),
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
        decoration: BoxDecoration(color: AppColors.premiumBlack, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: Colors.white70),
      ),
    );
  }
}
