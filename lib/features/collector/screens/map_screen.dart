import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../providers/collector_provider.dart';
import '../components/collector_map_tab.dart';
import 'pickups_screen.dart';
import 'earnings_screen.dart';
import '../components/collector_profile_tab.dart';

class CollectorMapScreen extends StatefulWidget {
  const CollectorMapScreen({super.key});

  @override
  State<CollectorMapScreen> createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  int _currentIndex = 0;
  LatLng? _pos;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final last = await LocationService.getLastKnownPosition();
    if (last != null && mounted) {
      setState(() => _pos = LatLng(last.latitude, last.longitude));
    }
    
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _pos = LatLng(pos.latitude, pos.longitude));
    }

    if (mounted) await context.read<CollectorProvider>().loadDashboard();

    _posSub = LocationService.getPositionStream().listen((p) {
      if (mounted) setState(() => _pos = LatLng(p.latitude, p.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CollectorMapTab(pos: _pos),
          const PickupsScreen(),
          const EarningsScreen(),
          const CollectorProfileTab(),
        ],
      ),
      bottomNavigationBar: _CollectorBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          _NavBtn(icon: PhosphorIconsRegular.mapTrifold, activeIcon: PhosphorIconsFill.mapTrifold, label: s.map),
          _NavBtn(icon: PhosphorIconsRegular.clipboardText, activeIcon: PhosphorIconsFill.clipboardText, label: s.pickups),
          _NavBtn(icon: PhosphorIconsRegular.coins, activeIcon: PhosphorIconsFill.coins, label: s.earnings),
          _NavBtn(icon: PhosphorIconsRegular.user, activeIcon: PhosphorIconsFill.user, label: s.profile),
        ],
      ),
    );
  }
}

class _CollectorBottomNav extends StatelessWidget {
  const _CollectorBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavBtn> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBtn {
  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
