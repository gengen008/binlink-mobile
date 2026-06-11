import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/l10n/strings.dart';
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
  // Last position used for zone subscription — used to detect significant moves
  ll.LatLng? _subscribedPos;
  StreamSubscription<Position>? _posSub;
  Timer? _collectorPollTimer;
  HouseholdProvider? _hp;

  // Minimum distance (meters) before re-subscribing to a new zone
  static const double _zoneResubscribeThresholdMeters = 800;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _collectorPollTimer?.cancel();
    _hp?.unsubscribeFromNearby();
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
    // Also triggers zone re-subscription if user moves significantly
    _posSub = LocationService.getPositionStream().listen((p) {
      if (!mounted) return;
      final newPos = ll.LatLng(p.latitude, p.longitude);
      setState(() => _myPos = newPos);

      // Re-subscribe to zone if user has moved more than threshold
      if (_hp != null && _subscribedPos != null) {
        final dist = Geolocator.distanceBetween(
          _subscribedPos!.latitude, _subscribedPos!.longitude,
          newPos.latitude, newPos.longitude,
        );
        if (dist > _zoneResubscribeThresholdMeters) {
          _hp!.unsubscribeFromNearby();
          _hp!.subscribeToNearby(newPos.latitude, newPos.longitude);
          _subscribedPos = newPos;
          // Also refresh REST collector list for new zone
          _hp!.loadOnlineCollectors(lat: newPos.latitude, lng: newPos.longitude);
        }
      }
    }, onError: (e) {
      // GPS toggled off / permission revoked mid-session — keep last known
      // position; the 30s poll keeps data fresh once GPS returns.
      debugPrint('[Home] Position stream error: $e');
    });

    if (!mounted) return;
    _hp = context.read<HouseholdProvider>();

    // Load data in parallel — pass GPS coords for proximity filtering
    final lat = _myPos?.latitude;
    final lng = _myPos?.longitude;
    await Future.wait([
      _hp!.loadBookings(),
      _hp!.loadOnlineCollectors(lat: lat, lng: lng),
      _hp!.loadSubscriptions(),
      _hp!.loadSavedAddresses(),
    ]);

    // Subscribe to real-time zone events so collector markers animate live
    if (_myPos != null && mounted) {
      _hp!.subscribeToNearby(_myPos!.latitude, _myPos!.longitude);
      _subscribedPos = _myPos;
    }

    // Periodic poll every 30s — catches collectors that joined between socket events
    _collectorPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _hp == null) return;
      final pos = _myPos;
      _hp!.loadOnlineCollectors(lat: pos?.latitude, lng: pos?.longitude);
    });
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
            icon: Icon(PhosphorIcons.house(PhosphorIconsStyle.regular)), 
            selectedIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
            label: s.home,
          ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.regular)), 
            selectedIcon: Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill)),
            label: s.history,
          ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.user(PhosphorIconsStyle.regular)), 
            selectedIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
            label: s.profile,
          ),
        ],
      ),
    );
  }
}
