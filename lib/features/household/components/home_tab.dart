import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show MapLibreMapController, CameraUpdate, LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/services/places_service.dart';
import '../../../core/utils/formatters.dart';
import '../providers/household_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/searching_radar_widget.dart';
import '../../../shared/widgets/collector_bottom_sheet.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/binlink_map.dart';
import 'service_selection_sheet.dart';
import 'address_selection_sheet.dart';
import '../screens/payment_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum HomeSheetState { idle, serviceSelection, addressSelection, searching, tracking }

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.myPos, required this.onTabSwitch});
  final ll.LatLng? myPos;
  final ValueChanged<int> onTabSwitch;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  MapLibreMapController? _mapController;
  HomeSheetState _sheetState = HomeSheetState.idle;

  String? _selectedCategory;
  String? _selectedBinSize;
  String _currentAddress = '';
  ll.LatLng? _pickupPosition;
  int _extraBags = 0;
  String? _preSelectedCategory;

  DateTime? _scheduledDate;
  String? _scheduledTimePreference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final active = context.read<HouseholdProvider>().activeBooking;
      if (active != null) {
        context.read<HouseholdProvider>().listenToBooking(active['id']);
      }
    });
  }

  @override
  void dispose() {
    // Only stop listening if we're actually tracking something
    if (_sheetState == HomeSheetState.tracking) {
      context.read<HouseholdProvider>().stopListening();
    }
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }


  void _startBookingFlow({String? category}) {
    if (widget.myPos == null) return;
    setState(() {
      _preSelectedCategory = category;
      _sheetState = HomeSheetState.serviceSelection;
      _pickupPosition = widget.myPos;
    });
  }

  void _onServiceSelected(String category, String binSize, int extraBags) async {
    final pos = _pickupPosition; // cache before async gap
    if (pos == null) return;

    setState(() {
      _selectedCategory = category;
      _selectedBinSize = binSize;
      _extraBags = extraBags;
    });

    final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);

    // Guard: user may have tapped Cancel during the geocoding await
    if (!mounted || _pickupPosition == null) return;

    setState(() {
      _currentAddress = address ?? 'Fetching address...';
      _sheetState = HomeSheetState.addressSelection;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(_pickupPosition!.latitude, _pickupPosition!.longitude), 16.5),
    );
  }

  Future<void> _onAddressConfirmed(String address) async {
    final pos = _pickupPosition; // cache before any async gap
    if (pos == null) return;

    try {
      final prov = context.read<HouseholdProvider>();

      // Choose payment method
      final method = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const _PaymentMethodPicker(),
      );

      if (method == null) return;

      // Guard: user may have cancelled while the sheet was open
      if (!mounted || _pickupPosition == null) return;

      if (method == 'MOMO') {
        final booking = await prov.createBooking(
          binSize: _selectedBinSize ?? 'SMALL',
          extraBags: _extraBags,
          pickupAddress: address,
          pickupLat: pos.latitude,
          pickupLng: pos.longitude,
          paymentMethod: 'MOMO',
          wasteCategory: _selectedCategory,
          scheduledDate: _scheduledDate,
          timePreference: _scheduledTimePreference,
          addressNotes: '',
        );

        if (booking != null && mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)));
        }
        return;
      }

      setState(() => _sheetState = HomeSheetState.searching);

      final booking = await prov.createBooking(
        binSize: _selectedBinSize ?? 'SMALL',
        extraBags: _extraBags,
        pickupAddress: address,
        pickupLat: pos.latitude,
        pickupLng: pos.longitude,
        paymentMethod: 'CASH',
        wasteCategory: _selectedCategory,
        scheduledDate: _scheduledDate,
        timePreference: _scheduledTimePreference,
        addressNotes: '',
      );

      if (booking != null && mounted) {
        prov.listenToBooking(booking['id']);
        setState(() => _sheetState = HomeSheetState.tracking);
      } else {
        if (mounted) setState(() => _sheetState = HomeSheetState.idle);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sheetState = HomeSheetState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  void _cancelBooking() {
    setState(() {
      _sheetState = HomeSheetState.idle;
      _pickupPosition = null;
      _scheduledDate = null;
      _scheduledTimePreference = null;
      _extraBags = 0;
    });
    if (widget.myPos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(widget.myPos!.latitude, widget.myPos!.longitude), 15),
      );
    }
  }

  Future<void> _startScheduleFlow() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SchedulePickerSheet(),
    );
    if (result == null || !mounted) return;
    _scheduledDate = result['date'] as DateTime;
    _scheduledTimePreference = result['timePreference'] as String;
    _startBookingFlow();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.myPos == null) return const _LocationLoadingView();

    final prov = context.watch<HouseholdProvider>();
    final active = prov.activeBooking;

    return Stack(
      children: [
        // ── Map ──
        Positioned.fill(
          child: BinLinkMap(
            initialPosition: widget.myPos!,
            onMapCreated: _onMapCreated,
            collectors: prov.onlineCollectors,
            pickupPosition: _pickupPosition,
            onCollectorTap: (c) {
              if (_sheetState == HomeSheetState.idle) {
                showCollectorSheet(context, c, onRequestPickup: _startBookingFlow);
              }
            },
          ),
        ),

        // ── Search Pill (Floating Top) ──
        if (_sheetState == HomeSheetState.idle)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: FadeInDown(
              child: _TopSearchPill(
                onSearchTap: _startBookingFlow,
              ),
            ),
          ),

        // ── Back Button (When Booking) ──
        if (_sheetState != HomeSheetState.idle)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: _FloatingCircularBtn(
              icon: LucideIcons.arrowLeft,
              onTap: _cancelBooking,
            ),
          ),

        // ── Locate Me ──
        Positioned(
          bottom: _sheetState == HomeSheetState.idle ? (active != null ? 400 : 350) : 420,
          right: 20,
          child: _FloatingCircularBtn(
            image: AppAssets.gps,
            onTap: () {
              if (widget.myPos != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(widget.myPos!.latitude, widget.myPos!.longitude), 15),
                );
              }
            },
          ),
        ),

        // ── Dynamic Sheets ──
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildBottomContent(active),
        ),
      ],
    );
  }

  Widget _buildBottomContent(Map<String, dynamic>? active) {
    final prov = context.read<HouseholdProvider>();

    // ── Multi-step Progress Indicator ──
    Widget? progressHeader;
    if ([HomeSheetState.serviceSelection, HomeSheetState.addressSelection].contains(_sheetState)) {
      final step = _sheetState == HomeSheetState.serviceSelection ? 1 : 2;
      progressHeader = Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepDot(isActive: step >= 1, isCompleted: step > 1),
                Container(width: 40, height: 2, color: step > 1 ? AppColors.primary : AppColors.border),
                _StepDot(isActive: step >= 2, isCompleted: step > 2),
                Container(width: 40, height: 2, color: step > 2 ? AppColors.primary : AppColors.border),
                _StepDot(isActive: step >= 3, isCompleted: step > 3),
              ],
            ),
          ],
        ),
      );
    }

    switch (_sheetState) {
      case HomeSheetState.idle:
        return _IdleBottomSheet(
          activeBooking: active,
          onRequestNow: _startBookingFlow,
          onSchedule: _startScheduleFlow,
          onShowTracking: () => setState(() => _sheetState = HomeSheetState.tracking),
          savedAddresses: prov.savedAddresses,
          onAddressTap: (a) => setState(() {
            _pickupPosition = ll.LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble());
            _currentAddress = a['address'] as String? ?? '';
            _sheetState = HomeSheetState.serviceSelection;
          }),
        );
      case HomeSheetState.serviceSelection:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progressHeader != null) progressHeader,
            ServiceSelectionSheet(
              initialCategory: _preSelectedCategory,
              onServiceSelected: _onServiceSelected,
              onCancel: _cancelBooking,
              showHandle: progressHeader == null,
            ),
          ],
        );
      case HomeSheetState.addressSelection:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progressHeader != null) progressHeader,
            AddressSelectionSheet(
              currentAddress: _currentAddress,
              onAddressConfirmed: _onAddressConfirmed,
              onCancel: _cancelBooking,
              showHandle: progressHeader == null,
            ),
          ],
        );
case HomeSheetState.searching:
  return _SearchingSheet(onCancel: _cancelBooking);
case HomeSheetState.tracking:
  return active != null ? _TrackingBottomSheet(booking: active) : const SizedBox();
}
}
}

class _StepDot extends StatelessWidget {
const _StepDot({required this.isActive, required this.isCompleted});
final bool isActive;
final bool isCompleted;

@override
Widget build(BuildContext context) {
return Container(
width: 12, height: 12,
decoration: BoxDecoration(
  color: isCompleted ? AppColors.primary : (isActive ? AppColors.primary : Colors.white),
  shape: BoxShape.circle,
  border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: 2),
),
child: isCompleted ? const Icon(LucideIcons.check, size: 8, color: Colors.white) : null,
);
}
}

// ── Components ──────────────────────────────────────────────────────────

class _TopSearchPill extends StatelessWidget {
  const _TopSearchPill({required this.onSearchTap});
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Text(
                "Where to collect from?",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 32, indent: 16, endIndent: 16),
          Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold), size: 22, color: AppColors.primary900),
        ],
      ),
    );
  }
}

class _FloatingCircularBtn extends StatelessWidget {
  const _FloatingCircularBtn({this.icon, this.image, required this.onTap});
  final IconData? icon;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: image != null 
          ? Image.asset(image!, width: 22, height: 22)
          : Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

class _IdleBottomSheet extends StatelessWidget {
  _IdleBottomSheet({
    this.activeBooking,
    required this.onRequestNow,
    required this.onSchedule,
    required this.onShowTracking,
    required this.savedAddresses,
    required this.onAddressTap,
  });
  final Map<String, dynamic>? activeBooking;
  final Function({String? category}) onRequestNow;
  final VoidCallback onSchedule;
  final VoidCallback onShowTracking;
  final List<Map<String, dynamic>> savedAddresses;
  final ValueChanged<Map<String, dynamic>> onAddressTap;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 3D Categories ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CategoryCardV4(image: AppAssets.bin3d, label: 'Household', onTap: () => onRequestNow(category: 'Household')),
              _CategoryCardV4(image: AppAssets.recycleBin, label: 'Recycling', onTap: () => onRequestNow(category: 'Recycling')),
              _CategoryCardV4(image: AppAssets.leaf, label: 'Organic', onTap: () => onRequestNow(category: 'Organic')),
              _CategoryCardV4(image: AppAssets.bottle, label: 'Plastic', onTap: () => onRequestNow(category: 'Plastic')),
              _CategoryCardV4(image: AppAssets.laptop, label: 'E-Waste', onTap: () => onRequestNow(category: 'E-Waste')),
              _CategoryCardV4(image: AppAssets.construction, label: 'Construction', onTap: () => onRequestNow(category: 'Construction')),
              _CategoryCardV4(image: AppAssets.trashPile, label: 'Metal', onTap: () => onRequestNow(category: 'Metal')),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Wallet & Rewards Row ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _WalletCard(points: user?.ecoPoints ?? 0),
              const SizedBox(width: 12),
              _RewardsCard(kg: user?.totalKgRecycled ?? 0.0),
              const SizedBox(width: 12),
              _PromoCard(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // ── Main Action Sheet ──
        FadeInUp(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeBooking != null) ...[
                  _ActiveBannerV4(booking: activeBooking!, onTap: onShowTracking),
                  const SizedBox(height: 24),
                ],

                Row(
                  children: [
                    Expanded(
                      child: _ActionBtnV4(
                        icon: LucideIcons.calendar,
                        title: "Schedule",
                        subtitle: "Plan ahead",
                        color: AppColors.surface,
                        borderColor: AppColors.border,
                        onTap: onSchedule,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionBtnV4(
                        icon: LucideIcons.zap,
                        title: "Request",
                        subtitle: "Instant pickup",
                        color: AppColors.premiumBlack,
                        textColor: Colors.white,
                        onTap: () => onRequestNow(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // ── Saved Addresses Section ──
                const Divider(),
                const SizedBox(height: 16),
                if (savedAddresses.isEmpty)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/saved-addresses'), // Assuming route exists
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Saved Addresses", style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
                              Text("Tap to add a new address", style: AppTextStyles.small.copyWith(color: AppColors.primary900)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Quick Pickup", style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      ...savedAddresses.take(3).map((a) => ListTile(
                        onTap: () => onAddressTap(a),
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(LucideIcons.mapPin, size: 18),
                        ),
                        title: Text(a['label'], style: AppTextStyles.title.copyWith(fontSize: 16)),
                        subtitle: Text(a['address'], style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.wallet, color: Colors.white, size: 18),
          const Spacer(),
          Text('Eco Balance', style: AppTextStyles.small.copyWith(color: Colors.white70)),
          Text('$points pts', style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.kg});
  final double kg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.success.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.leaf, color: Colors.white, size: 18),
          const Spacer(),
          Text('Total Saved', style: AppTextStyles.small.copyWith(color: Colors.white70)),
          Text('${kg.toStringAsFixed(1)} kg', style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary700,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary700.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.gift, color: Colors.white, size: 18),
          const Spacer(),
          Text('Rewards', style: AppTextStyles.small.copyWith(color: Colors.white70)),
          Text('View all', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}


class _CategoryCardV4 extends StatelessWidget {
  _CategoryCardV4({required this.image, required this.label, required this.onTap});
  final String image;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ActionBtnV4 extends StatelessWidget {
  _ActionBtnV4({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.textColor,
    this.borderColor,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(24),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor ?? AppColors.textPrimary, size: 24),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h3.copyWith(color: textColor ?? AppColors.textPrimary)),
            Text(subtitle, style: AppTextStyles.label.copyWith(color: (textColor ?? AppColors.textSecondary).withAlpha(180))),
          ],
        ),
      ),
    );
  }
}

class _ActiveBannerV4 extends StatelessWidget {
  _ActiveBannerV4({required this.booking, required this.onTap});
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset(AppAssets.truck3d, width: 24, height: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Active Booking", style: AppTextStyles.h4.copyWith(color: Colors.white)),
                  Text(Fmt.statusLabel(booking['status'] ?? ''), style: AppTextStyles.label.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SearchingSheet extends StatefulWidget {
  const _SearchingSheet({required this.onCancel});
  final VoidCallback onCancel;
  @override
  State<_SearchingSheet> createState() => _SearchingSheetState();
}

class _SearchingSheetState extends State<_SearchingSheet> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SearchingRadarWidget(radius: 100, ringColor: AppColors.primary),
                Lottie.asset(
                  AppAssets.lottieSearching,
                  width: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: Icon(LucideIcons.truck, color: AppColors.primary, size: 40),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Finding your collector', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Searching... $_seconds s', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          AppButton(
            label: 'Cancel Request',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              final prov = context.read<HouseholdProvider>();
              final activeId = prov.activeBooking?['id'];
              if (activeId != null) prov.cancelBooking(activeId);
              widget.onCancel(); // reset parent state to idle
            },
          ),
        ],
      ),
    );
  }
}

class _TrackingBottomSheet extends StatelessWidget {
  const _TrackingBottomSheet({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'PENDING';
    final collector = booking['collector'];
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status == 'ACCEPTED' || status == 'EN_ROUTE' ? "Calculating ETA..." : "Pickup in progress", style: AppTextStyles.h2.copyWith(color: AppColors.primary900)),
                  Text(Fmt.statusLabel(status), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary300.withAlpha(50), shape: BoxShape.circle),
                child: const Icon(LucideIcons.truck, color: AppColors.primary900, size: 24),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          _TrackingStatusProgressBar(status: status),
          const SizedBox(height: 32),
          if (collector != null) ...[
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.background,
                      backgroundImage: collector['profilePhoto'] != null 
                        ? NetworkImage(collector['profilePhoto']) 
                        : null,
                      child: collector['profilePhoto'] == null 
                        ? Text(Fmt.initials(collector['fullName']), style: AppTextStyles.h3)
                        : null,
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collector['fullName'] ?? 'Collector', style: AppTextStyles.title),
                      Row(
                        children: [
                          const Icon(LucideIcons.star, color: AppColors.warning, size: 14),
                          const SizedBox(width: 4),
                          Text(collector['rating']?.toString() ?? '5.0', style: AppTextStyles.small.copyWith(color: AppColors.textPrimary)),
                          const SizedBox(width: 12),
                          Text(collector['vehiclePlate'] ?? 'No Plate', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                _RoundIconBtn(icon: LucideIcons.phone, onTap: () => launchUrl(Uri.parse('tel:${collector['phone'] ?? ''}'))),
                const SizedBox(width: 12),
                _RoundIconBtn(icon: LucideIcons.messageCircle, onTap: () => showChatSheet(context, bookingId: booking['id'], myRole: 'HOUSEHOLD')),
              ],
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(booking['pickupAddress'] ?? '', style: AppTextStyles.body)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15), 
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withAlpha(30)),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}

class _SchedulePickerSheet extends StatefulWidget {
  const _SchedulePickerSheet();
  @override
  State<_SchedulePickerSheet> createState() => _SchedulePickerSheetState();
}

class _SchedulePickerSheetState extends State<_SchedulePickerSheet> {
  late DateTime _selectedDate;
  String _timePreference = 'MORNING';

  static const _timeSlots = [
    ('MORNING',   'Morning',   '7am – 11am'),
    ('AFTERNOON', 'Afternoon', '12pm – 4pm'),
    ('EVENING',   'Evening',   '4pm – 7pm'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(14, (i) => today.add(Duration(days: i + 1)));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          Text('Schedule Pickup', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (_, i) {
                final d = dates[i];
                final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month;
                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayNames[d.weekday - 1], style: AppTextStyles.label.copyWith(color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('${d.day}', style: AppTextStyles.h3.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 22)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text('Time Preference', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          Row(
            children: _timeSlots.map((slot) {
              final (id, label, hours) = slot;
              final isSelected = _timePreference == id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _timePreference = id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(label, style: AppTextStyles.h4.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
                        Text(hours, style: AppTextStyles.label.copyWith(fontSize: 10, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Confirm Schedule',
            onPressed: () => Navigator.pop(context, {'date': _selectedDate, 'timePreference': _timePreference}),
          ),
        ],
      ),
    );
  }
}

class _LocationLoadingView extends StatelessWidget {
  const _LocationLoadingView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              AppAssets.lottieLoading,
              width: 150,
              errorBuilder: (context, error, stackTrace) => CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text('Locating you...', style: AppTextStyles.h3),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  const _PaymentMethodPicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          Text('Payment Method', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          _PaymentOption(
            label: 'Cash on Pickup',
            icon: LucideIcons.banknote,
            onTap: () => Navigator.pop(context, 'CASH'),
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            label: 'Mobile Money',
            icon: LucideIcons.smartphone,
            onTap: () => Navigator.pop(context, 'MOMO'),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
      title: Text(label, style: AppTextStyles.h4),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
    );
  }
}

class _TrackingStatusProgressBar extends StatelessWidget {
  const _TrackingStatusProgressBar({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final stages = ['ACCEPTED', 'EN_ROUTE', 'ARRIVED', 'COLLECTING'];
    int currentIndex = stages.indexOf(status);
    if (currentIndex == -1) {
      if (['COMPLETED', 'COLLECTED'].contains(status)) currentIndex = stages.length;
      else currentIndex = 0;
    }

    return Column(
      children: [
        Row(
          children: List.generate(stages.length, (i) {
            final isActive = i <= currentIndex;
            final isLast = i == stages.length - 1;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (!isLast) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatusLabel(label: 'Assigned', isActive: currentIndex >= 0),
            _StatusLabel(label: 'On Way',   isActive: currentIndex >= 1),
            _StatusLabel(label: 'Arrived',  isActive: currentIndex >= 2),
            _StatusLabel(label: 'Collecting', isActive: currentIndex >= 3),
          ],
        ),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.small.copyWith(
        color: isActive ? AppColors.primary : AppColors.textMuted,
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
        fontSize: 10,
      ),
    );
  }
}
