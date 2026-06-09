import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(myPos: _myPos, onTabSwitch: _onTabChanged),
          const HistoryTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.house), 
            selectedIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
            label: s.home,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.history), 
            selectedIcon: Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill)),
            label: s.history,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.user), 
            selectedIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
            label: s.profile,
          ),
        ],
      ),
    );
  }
}
