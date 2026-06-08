import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../providers/household_provider.dart';
import '../components/home_tab.dart';
import '../components/history_tab.dart';
import '../components/profile_tab.dart';

class HouseholdHomeScreen extends StatefulWidget {
  const HouseholdHomeScreen({super.key});

  @override
  State<HouseholdHomeScreen> createState() => _HouseholdHomeScreenState();
}

class _HouseholdHomeScreenState extends State<HouseholdHomeScreen> {
  int _currentIndex = 0;
  // Null until the device provides a real GPS fix — never hardcoded.
  ll.LatLng? _myPos;
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
    // Phase 1: last-known — fast, may be slightly stale
    final lastKnown = await LocationService.getLastKnownPosition();
    if (lastKnown != null && mounted) {
      setState(() => _myPos = ll.LatLng(lastKnown.latitude, lastKnown.longitude));
    }

    // Phase 2: fresh GPS fix — accurate
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _myPos = ll.LatLng(pos.latitude, pos.longitude));
    }

    // Phase 3: live stream — updates whenever user moves ≥10 m
    _posSub = LocationService.getPositionStream().listen((p) {
      if (mounted) setState(() => _myPos = ll.LatLng(p.latitude, p.longitude));
    });

    if (!mounted) return;
    final hp = context.read<HouseholdProvider>();
    await Future.wait([
      hp.loadBookings(),
      hp.loadOnlineCollectors(),
      hp.loadSubscriptions(),
    ]);
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      drawer: AppDrawer(onTabSwitch: _onTabChanged),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(myPos: _myPos, onTabSwitch: _onTabChanged),
          const HistoryTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BinLinkBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: [
          _NavBtn(
            icon: PhosphorIconsRegular.house,
            activeIcon: PhosphorIconsFill.house,
            label: s.home,
          ),
          _NavBtn(
            icon: PhosphorIconsRegular.clockCounterClockwise,
            activeIcon: PhosphorIconsFill.clockCounterClockwise,
            label: s.history,
          ),
          _NavBtn(
            icon: PhosphorIconsRegular.user,
            activeIcon: PhosphorIconsFill.user,
            label: s.profile,
          ),
        ],
      ),
    );
  }
}

class _BinLinkBottomNav extends StatelessWidget {
  const _BinLinkBottomNav({
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
