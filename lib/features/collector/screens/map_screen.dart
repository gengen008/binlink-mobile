import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/strings.dart';
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
    }, onError: (e) {
      // GPS toggled off / permission revoked — keep last known position
      debugPrint('[CollectorMap] Position stream error: $e');
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.map), 
            selectedIcon: Icon(PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill)),
            label: s.map,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.clipboardList), 
            selectedIcon: Icon(PhosphorIcons.clipboardText(PhosphorIconsStyle.fill)),
            label: s.pickups,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.coins), 
            selectedIcon: Icon(PhosphorIcons.coins(PhosphorIconsStyle.fill)),
            label: s.earnings,
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
