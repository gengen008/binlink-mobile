import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../screens/book_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/saved_addresses_screen.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/collector_bottom_sheet.dart';
import '../../../shared/widgets/searching_radar_widget.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.myPos, required this.onTabSwitch});
  final LatLng myPos;
  final ValueChanged<int> onTabSwitch;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  MapLibreMapController? _mapCtrl;
  final Map<String, Map<String, dynamic>> _circleIdToData = {};

  @override
  void dispose() {
    _mapCtrl?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapCtrl = controller;
    _mapCtrl!.onCircleTapped.add(_onCircleTapped);
    _updateCollectorMarkers();
  }

  void _onCircleTapped(Circle circle) {
    final data = _circleIdToData[circle.id];
    if (data != null) {
      showCollectorSheet(
        context,
        data,
        onRequestPickup: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen())),
      );
    }
  }

  void _updateCollectorMarkers() async {
    if (_mapCtrl == null) return;
    final collectors = context.read<HouseholdProvider>().onlineCollectors;
    await _mapCtrl!.clearCircles();
    _circleIdToData.clear();

    for (var c in collectors) {
      final lat = (c['lastLat'] as num?)?.toDouble();
      final lng = (c['lastLng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final circle = await _mapCtrl!.addCircle(
        CircleOptions(
          geometry: LatLng(lat, lng),
          circleRadius: 10,
          circleColor: '#16A34A',
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _circleIdToData[circle.id] = Map<String, dynamic>.from(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<HouseholdProvider>();
    final user = auth.user;
    final active = prov.activeBooking;
    final bookings = prov.bookings.take(3).toList();
    
    final firstName = user?.fullName?.split(' ').first ?? 'there';
    final nearbyCount = prov.onlineCollectors.length;

    // Trigger marker update when collectors list changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCollectorMarkers();
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $firstName', style: AppTextStyles.title),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.mapPin, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user?.address ?? 'Set your location',
                                style: AppTextStyles.meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: user?.profilePhoto != null 
                      ? ClipOval(child: Image.network(user!.profilePhoto!, fit: BoxFit.cover))
                      : Text(Fmt.initials(user?.fullName ?? 'U'), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _SplitCTA(
                      label: 'Request Now',
                      sub: '~15 min arrival',
                      icon: PhosphorIconsFill.lightning,
                      isPrimary: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate'))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SplitCTA(
                      label: 'Schedule',
                      sub: 'Pick date & time',
                      icon: PhosphorIconsFill.calendarBlank,
                      isPrimary: false,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'scheduled'))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionBtn(
                      icon: PhosphorIconsRegular.mapPin,
                      label: 'Addresses',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionBtn(
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      label: 'History',
                      onTap: () => widget.onTabSwitch(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionBtn(
                      icon: PhosphorIconsRegular.user,
                      label: 'Profile',
                      onTap: () => widget.onTabSwitch(2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (active != null) ...[
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: _ActiveBookingCard(
                    booking: active,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: active['id'])),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text('Nearby Collectors', style: AppTextStyles.section),
              const SizedBox(height: 12),
              
              ClipRRect(
                borderRadius: AppRadius.mdBR,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdBR,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      MapLibreMap(
                        styleString: kMapStyleUrl,
                        initialCameraPosition: CameraPosition(target: widget.myPos, zoom: 14),
                        onMapCreated: _onMapCreated,
                        myLocationEnabled: false,
                        trackCameraPosition: true,
                      ),
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadius.smBR, border: Border.all(color: AppColors.border)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text('$nearbyCount available', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12, right: 12,
                        child: FloatingActionButton.small(
                          onPressed: () => _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(widget.myPos, 15)),
                          backgroundColor: Colors.white,
                          child: const Icon(PhosphorIconsRegular.crosshair, color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              if (bookings.isNotEmpty) ...[
                Text('Recent Pickups', style: AppTextStyles.section),
                const SizedBox(height: 12),
                ...bookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingCard(
                    booking: b, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: b['id'])))
                  ),
                )),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitCTA extends StatelessWidget {
  const _SplitCTA({required this.label, required this.sub, required this.icon, required this.isPrimary, required this.onTap});
  final String label;
  final String sub;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBR,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: AppRadius.mdBR,
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.bodyMedium.copyWith(color: isPrimary ? Colors.white : AppColors.secondary, fontWeight: FontWeight.w700)),
            Text(sub, style: AppTextStyles.caption.copyWith(color: isPrimary ? Colors.white.withAlpha(200) : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBR,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard({required this.booking, required this.onTap});
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'PENDING';
    final isSearching = status == 'PENDING' || status == 'SEARCHING';
    final collector = booking['collector'] as Map<String, dynamic>?;
    
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBR,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSearching) const SearchingRadarWidget(radius: 24),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(PhosphorIconsFill.truck, color: AppColors.primary, size: 24),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSearching ? 'Searching...' : 'Collector Arriving', style: AppTextStyles.section.copyWith(color: AppColors.primary)),
                  Text(isSearching ? 'Finding nearby collectors' : (collector?['fullName'] ?? 'On the way'), style: AppTextStyles.meta),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
