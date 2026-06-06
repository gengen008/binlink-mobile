import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../screens/book_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/saved_addresses_screen.dart';
import '../../../shared/widgets/collector_bottom_sheet.dart';
import '../../../shared/widgets/searching_radar_widget.dart';
import '../../../shared/widgets/binlink_map.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.myPos, required this.onTabSwitch});
  final LatLng myPos;
  final ValueChanged<int> onTabSwitch;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<HouseholdProvider>();
    final user = auth.user;
    final active = prov.activeBooking;
    final saved = prov.savedAddresses.take(2).toList();
    
    final firstName = user?.fullName?.split(' ').first ?? 'there';

    return Stack(
      children: [
        // ── Full Screen Map ─────────────────────────────────────────────────
        Positioned.fill(
          child: BinLinkMap(
            initialPosition: widget.myPos,
            onMapCreated: _onMapCreated,
            markers: prov.onlineCollectors.map((c) {
              return Marker(
                markerId: MarkerId(c['id']),
                position: LatLng(
                  (c['lastLat'] as num).toDouble(),
                  (c['lastLng'] as num).toDouble(),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                onTap: () => showCollectorSheet(
                  context,
                  c,
                  onRequestPickup: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen())),
                ),
              );
            }).toSet(),
          ),
        ),

        // ── Top Bar: Menu & Search Overlay ──────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Icon(PhosphorIconsRegular.list, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.fullBR,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.magnifyingGlass, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text("Where to pickup?", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Locate Me Button ────────────────────────────────────────────────
        Positioned(
          bottom: 240, // Above bottom sheet
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(widget.myPos, 15)),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 4,
            child: const Icon(PhosphorIconsRegular.crosshair),
          ),
        ),

        // ── Bottom Interface ────────────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBR,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (active != null) ...[
                  _ActiveBookingCard(
                    booking: active,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: active['id'])),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Text(
                  "Hey, $firstName 👋",
                  style: AppTextStyles.section.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SplitCard(
                        icon: PhosphorIconsFill.lightning,
                        title: "Request Now",
                        subtitle: "Arrives in ~15m",
                        isPrimary: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SplitCard(
                        icon: PhosphorIconsRegular.calendar,
                        title: "Schedule",
                        subtitle: "Pick date & time",
                        isPrimary: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookScreen(mode: 'scheduled')),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                
                if (saved.isEmpty)
                  _SavedLocationTile(
                    icon: PhosphorIconsRegular.plus,
                    title: "Add a saved address",
                    subtitle: "Get picked up faster",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                  )
                else
                  ...saved.map((addr) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SavedLocationTile(
                      icon: addr['label'] == 'Work' ? PhosphorIconsFill.briefcase : PhosphorIconsFill.house,
                      title: addr['label'] ?? 'Saved Address',
                      subtitle: addr['address'] ?? '',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate')),
                      ),
                    ),
                  )),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: AppRadius.smBR,
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary ? [
            BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              color: isPrimary ? Colors.white : AppColors.primary, 
              size: 28
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.section.copyWith(
                color: isPrimary ? Colors.white : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: isPrimary ? Colors.white.withAlpha(200) : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedLocationTile extends StatelessWidget {
  const _SavedLocationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
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
                if (isSearching) SearchingRadarWidget(radius: 24),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsFill.truck, color: AppColors.primary, size: 24),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSearching ? 'Searching...' : 'Collector Arriving', style: AppTextStyles.section.copyWith(color: AppColors.primary)),
                  Text(isSearching ? 'Finding nearby collectors' : 'On the way', style: AppTextStyles.meta),
                ],
              ),
            ),
            Icon(PhosphorIconsRegular.caretRight, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
