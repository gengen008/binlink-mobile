import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../screens/saved_addresses_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/edit_profile_screen.dart';
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
      backgroundColor: AppColors.surface,
      appBar: const AppScaffoldBar(
        title: 'Profile',
        showBack: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Profile Info ──────────────────────────────────────────────────
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
                      Fmt.initials(user?.fullName ?? 'U'),
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'BinLink User', style: AppTextStyles.section),
                        Text(user?.email ?? '', style: AppTextStyles.meta),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                    icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Stats Row (PASS E) ───────────────────────────────────────────
            _StatsRow(
              items: [
                _StatItem(label: 'Pickups', value: '${user?.totalPickups ?? 0}'),
                _StatItem(label: 'Recycled', value: '${user?.totalKgRecycled.toInt() ?? 0} kg'),
                _StatItem(label: 'Eco Points', value: '${user?.ecoPoints ?? 0}'),
              ],
            ),

            const SizedBox(height: 32),

            // ── Menu List ─────────────────────────────────────────────────────
            _MenuTile(
              icon: PhosphorIconsRegular.mapPin,
              label: 'Saved Addresses',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
              ),
            ),
            _MenuTile(
              icon: PhosphorIconsRegular.calendarCheck,
              label: 'Subscriptions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
              ),
            ),
            _MenuTile(
              icon: PhosphorIconsRegular.question,
              label: 'Help & Support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            _MenuTile(
              icon: PhosphorIconsRegular.shieldCheck,
              label: 'Privacy Policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
            ),

            const SizedBox(height: 32),

            // ── Logout ────────────────────────────────────────────────────────
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
