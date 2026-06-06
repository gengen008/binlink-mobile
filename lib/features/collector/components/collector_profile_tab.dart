import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
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
      backgroundColor: AppColors.surface,
      appBar: const AppScaffoldBar(
        title: 'Profile',
        showBack: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      Fmt.initials(user?.fullName ?? 'C'),
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Collector', style: AppTextStyles.section),
                        Text(user?.email ?? '', style: AppTextStyles.meta),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorEditProfileScreen())),
                    icon: const Icon(PhosphorIconsRegular.pencilSimple),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Stats Row (PASS E) ──────────────────────────────────────────
            _StatsRow(
              items: [
                _StatItem(label: 'Jobs', value: '${user?.totalPickups ?? 0}'),
                _StatItem(label: 'Earned', value: Fmt.currency(Fmt.toDouble(user?.totalEarned ?? 0))),
                _StatItem(label: 'Rating', value: '${user?.rating ?? 5.0} ★'),
              ],
            ),

            const SizedBox(height: 32),

            // ── Menu ────────────────────────────────────────────────────────
            _ProfileMenuTile(
              icon: PhosphorIconsRegular.truck,
              label: 'Vehicle Details',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleDetailsScreen())),
            ),
            _ProfileMenuTile(
              icon: PhosphorIconsRegular.bell,
              label: 'Notifications',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorNotificationsScreen())),
            ),
            _ProfileMenuTile(
              icon: PhosphorIconsRegular.question,
              label: 'Help & Support',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorHelpScreen())),
            ),
            _ProfileMenuTile(
              icon: PhosphorIconsRegular.shieldCheck,
              label: 'Privacy & Security',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorPrivacyScreen())),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => auth.signOut(),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsRegular.signOut, size: 20),
                    const SizedBox(width: 8),
                    Text('Log Out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: isLast ? null : const Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Text(e.value.value, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(e.value.label, style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBR,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.mdBR,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.secondary),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              const Icon(PhosphorIconsRegular.caretRight, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
