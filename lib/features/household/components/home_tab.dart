import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_assets.dart';
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
  MapLibreMapController? _mapController;

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final active = prov.activeBooking;
    final saved = prov.savedAddresses.take(2).toList();
    
    return Stack(
      children: [
        // ── Full Screen Map ─────────────────────────────────────────────────
        Positioned.fill(
          child: BinLinkMap(
            initialPosition: widget.myPos,
            onMapCreated: _onMapCreated,
            collectors: prov.onlineCollectors,
            onCollectorTap: (c) => showCollectorSheet(
              context,
              c,
              onRequestPickup: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookScreen()),
              ),
            ),
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
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate'))),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.fullBR,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Image.asset(AppAssets.search, width: 22, height: 22, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text("Where to pickup?", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Locate Me Button ────────────────────────────────────────────────
        Positioned(
          bottom: active != null ? 350 : 300, // Adjust based on sheet height
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () => _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(widget.myPos, 15),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(PhosphorIconsRegular.crosshair),
          ),
        ),

        // ── Bottom Interface (Uber Style) ──────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Suggestions Horizontal List (Uber Inspiration) ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SuggestionCard(
                      image: AppAssets.trashBin,
                      title: 'Household',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate'))),
                    ),
                    _SuggestionCard(
                      image: AppAssets.recycleBin,
                      title: 'Recycling',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate'))),
                    ),
                    _SuggestionCard(
                      image: AppAssets.bottle,
                      title: 'Glass/Plastic',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate'))),
                    ),
                    _SuggestionCard(
                      image: AppAssets.leaf,
                      title: 'Organic',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate'))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // ── Main White Sheet ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.sheetBR,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
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
                      const SizedBox(height: 20),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: _SplitCard(
                            image: AppAssets.calendar,
                            title: "Schedule",
                            subtitle: "Plan ahead",
                            isPrimary: false,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookScreen(mode: 'scheduled')),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SplitCard(
                            image: AppAssets.clock,
                            title: "Request Now",
                            subtitle: "Instant pickup",
                            isPrimary: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookScreen(mode: 'immediate')),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.image, required this.title, required this.onTap});
  final String image;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBR,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Image.asset(image, width: 28, height: 28),
            const SizedBox(width: 10),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  final String image;
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
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.mdBR,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              image, 
              width: 32, height: 32,
              color: isPrimary ? Colors.white : AppColors.primary,
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
            padding: const EdgeInsets.all(10),
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
          const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textMuted),
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
          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSearching) SearchingRadarWidget(radius: 24, ringColor: AppColors.primary),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: Image.asset(AppAssets.truck, width: 24, height: 24, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSearching ? 'Searching...' : 'Collector Arriving', style: AppTextStyles.section.copyWith(color: AppColors.primary, fontSize: 16)),
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
