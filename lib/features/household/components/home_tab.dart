import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show MapController;
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/services/places_service.dart';
import '../../../core/utils/formatters.dart';
import '../providers/household_provider.dart';
import '../../../shared/widgets/collector_bottom_sheet.dart';
import '../../../shared/widgets/searching_radar_widget.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/binlink_map.dart';
import 'service_selection_sheet.dart';
import 'address_selection_sheet.dart';

enum HomeSheetState { idle, serviceSelection, addressSelection, searching, tracking }

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.myPos, required this.onTabSwitch});
  // Nullable: null until the device provides a real GPS fix.
  final LatLng? myPos;
  final ValueChanged<int> onTabSwitch;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  MapController? _mapController;
  HomeSheetState _sheetState = HomeSheetState.idle;
  
  // Booking Data
  String? _selectedCategory;
  String? _selectedBinSize;
  String _currentAddress = '';
  LatLng? _pickupPosition;
  int _extraBags = 0;

  // Schedule Data (null = immediate pickup)
  DateTime? _scheduledDate;
  String? _scheduledTimePreference;

  void _onMapCreated(MapController controller) {
    _mapController = controller;
  }

  void _startBookingFlow() {
    if (widget.myPos == null) return; // GPS not ready yet
    setState(() {
      _sheetState = HomeSheetState.serviceSelection;
      _pickupPosition = widget.myPos;
    });
  }

  void _onServiceSelected(String category, String binSize, int extraBags) async {
    setState(() {
      _selectedCategory = category;
      _selectedBinSize = binSize;
      _extraBags = extraBags;
    });

    // Try to get address for the pin
    final address = await PlacesService.reverseGeocode(
        _pickupPosition!.latitude, _pickupPosition!.longitude);
    
    if (mounted) {
      setState(() {
        _currentAddress = address ?? 'Fetching address...';
        _sheetState = HomeSheetState.addressSelection;
      });
      // Zoom into pin
      _mapController?.move(_pickupPosition!, 16.5);
    }
  }

  Future<void> _onAddressConfirmed(String address) async {
    setState(() {
      _sheetState = HomeSheetState.searching;
    });

    final prov = context.read<HouseholdProvider>();
    final booking = await prov.createBooking(
      binSize: _selectedBinSize ?? 'SMALL',
      extraBags: _extraBags,
      pickupAddress: address,
      pickupLat: _pickupPosition!.latitude,
      pickupLng: _pickupPosition!.longitude,
      paymentMethod: 'CASH',
      wasteCategory: _selectedCategory,
      scheduledDate: _scheduledDate,
      timePreference: _scheduledTimePreference,
      addressNotes: '',
    );

    if (booking != null && mounted) {
      // Transition directly to Tracking state, matching Bolt/Uber seamless flow
      setState(() => _sheetState = HomeSheetState.tracking);
    } else {
      if (mounted) setState(() => _sheetState = HomeSheetState.idle);
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
    if (widget.myPos != null) _mapController?.move(widget.myPos!, 15);
  }

  /// Opens a schedule date/time picker sheet. On confirmation transitions
  /// into the normal booking flow with the chosen date pre-loaded.
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
    // Show a full-screen loader until we have a real GPS position.
    // This prevents the map from ever defaulting to a hardcoded location.
    if (widget.myPos == null) {
      return const _LocationLoadingView();
    }

    final prov = context.watch<HouseholdProvider>();
    final active = prov.activeBooking;

    return Stack(
      children: [
        // ── Full Screen Map ─────────────────────────────────────────────────
        Positioned.fill(
          child: BinLinkMap(
            initialPosition: widget.myPos!,
            onMapCreated: _onMapCreated,
            collectors: prov.onlineCollectors,
            pickupPosition: _pickupPosition,
            onCollectorTap: (c) {
              if (_sheetState == HomeSheetState.idle) {
                showCollectorSheet(
                  context,
                  c,
                  onRequestPickup: _startBookingFlow,
                );
              }
            },
          ),
        ),

        // ── Top Bar: Menu (Only visible in idle) ────────────────────────────
        if (_sheetState == HomeSheetState.idle)
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
                    onTap: _startBookingFlow, // search bar = immediate booking
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

        // ── Top Bar: Back Button (Visible when booking) ─────────────────────
        if (_sheetState != HomeSheetState.idle)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: _cancelBooking,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Icon(PhosphorIconsRegular.arrowLeft, size: 24),
              ),
            ),
          ),

        // ── Locate Me Button ────────────────────────────────────────────────
        Positioned(
          bottom: _sheetState == HomeSheetState.idle ? (active != null ? 350 : 300) : 400,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () => _mapController?.move(widget.myPos!, 15),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 4,
            shape: const CircleBorder(),
            child: Image.asset(AppAssets.gps, width: 20, height: 20, color: AppColors.textPrimary),
          ),
        ),

        // ── Dynamic Bottom Sheets ──────────────────────────────────────────
        if (_sheetState == HomeSheetState.idle)
          Align(
            alignment: Alignment.bottomCenter,
            child: _IdleBottomSheet(
              activeBooking: active,
              onRequestNow: _startBookingFlow,
              onSchedule: _startScheduleFlow,
              onShowTracking: active != null
                  ? () => setState(() => _sheetState = HomeSheetState.tracking)
                  : null,
            ),
          )
        else if (_sheetState == HomeSheetState.serviceSelection)
          ServiceSelectionSheet(
            onServiceSelected: _onServiceSelected,
            onCancel: _cancelBooking,
          )
        else if (_sheetState == HomeSheetState.addressSelection)
          AddressSelectionSheet(
            currentAddress: _currentAddress,
            onAddressConfirmed: _onAddressConfirmed,
            onCancel: _cancelBooking,
          )
        else if (_sheetState == HomeSheetState.searching)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 48),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchingRadarWidget(radius: 40, ringColor: AppColors.primary),
                  const SizedBox(height: 24),
                  Text('Searching for nearby collectors...', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text('Please wait while we match you.', style: AppTextStyles.body),
                ],
              ),
            ),
          )
        else if (_sheetState == HomeSheetState.tracking && active != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: _TrackingBottomSheet(booking: active),
          ),
      ],
    );
  }
}

class _IdleBottomSheet extends StatelessWidget {
  const _IdleBottomSheet({
    this.activeBooking,
    required this.onRequestNow,
    required this.onSchedule,
    this.onShowTracking,
  });
  final Map<String, dynamic>? activeBooking;
  final VoidCallback onRequestNow;
  final VoidCallback onSchedule;
  final VoidCallback? onShowTracking;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onTap: onRequestNow,
              ),
              _SuggestionCard(
                image: AppAssets.recycleBin,
                title: 'Recycling',
                onTap: onRequestNow,
              ),
              _SuggestionCard(
                image: AppAssets.bottle,
                title: 'Glass/Plastic',
                onTap: onRequestNow,
              ),
              _SuggestionCard(
                image: AppAssets.leaf,
                title: 'Organic',
                onTap: onRequestNow,
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
              if (activeBooking != null) ...[
                _ActiveBookingCard(
                  booking: activeBooking!,
                  onTap: onShowTracking ?? () {},
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
                      onTap: onSchedule,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SplitCard(
                      image: AppAssets.clock,
                      title: "Request Now",
                      subtitle: "Instant pickup",
                      isPrimary: true,
                      onTap: onRequestNow,
                    ),
                  ),
                ],
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

// ── Schedule Picker Sheet ──────────────────────────────────────────────────────
// Shown when user taps "Schedule" CTA. Lets them pick a date (next 14 days)
// and a time preference. Returns {'date': DateTime, 'timePreference': String}.

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Schedule Pickup', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 14-day date carousel ──────────────────────────────────────────
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: dates.length,
              itemBuilder: (_, i) {
                final d = dates[i];
                final isSelected = d.day == _selectedDate.day &&
                    d.month == _selectedDate.month;
                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final dayName = dayNames[d.weekday - 1];
                final monthNames = [
                  'Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'
                ];

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white.withAlpha(200) : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: AppTextStyles.h3.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          monthNames[d.month - 1],
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white.withAlpha(180) : AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Time Preference', style: AppTextStyles.section),
          ),
          const SizedBox(height: 12),

          // ── Time preference chips ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _timeSlots.map((slot) {
                final (id, label, hours) = slot;
                final isSelected = _timePreference == id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _timePreference = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hours,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'date': _selectedDate,
                  'timePreference': _timePreference,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Confirm Schedule',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Getting your location...',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
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
    
    final (pngAsset, fallbackIcon, msg, color) = switch (status) {
      'PENDING'    => (null, PhosphorIconsFill.clock, 'Finding your collector...', AppColors.warning),
      'ACCEPTED'   => (AppAssets.verifiedBadge, null, 'Collector accepted', AppColors.success),
      'EN_ROUTE'   => (AppAssets.truck, null, 'Collector is on the way', AppColors.info),
      'ON_THE_WAY' => (AppAssets.truck, null, 'Collector is on the way', AppColors.info),
      'ARRIVED'    => (AppAssets.gps, null, 'Collector has arrived', AppColors.success),
      'COLLECTING' => (AppAssets.gps, null, 'Collecting your waste', AppColors.success),
      'COMPLETED'  => (AppAssets.verifiedBadge, null, 'Pickup completed', AppColors.success),
      _            => (null, PhosphorIconsFill.info, status, AppColors.textSecondary),
    };

    Widget iconWidget;
    if (pngAsset != null) {
      iconWidget = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Image.asset(pngAsset, width: 22, height: 22, color: color),
      );
    } else {
      iconWidget = Icon(fallbackIcon!, color: color, size: 24);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.sheetBR,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: AppTextStyles.section.copyWith(color: color))),
            ],
          ),
          const SizedBox(height: 24),
          if (booking['collector'] != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surface,
                  child: Text(Fmt.initials(booking['collector']['fullName'])),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['collector']['fullName'] ?? 'Collector', style: AppTextStyles.section),
                      Text(
                        booking['collector']['vehiclePlate'] != null
                            ? "Vehicle #${booking['collector']['vehiclePlate']}"
                            : "Collector Vehicle",
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => launchUrl(Uri.parse('tel:${booking['collector']['phone'] ?? ''}')),
                  icon: const Icon(PhosphorIconsFill.phone),
                ),
                IconButton(
                  onPressed: () => showChatSheet(context, bookingId: booking['id'], myRole: 'HOUSEHOLD'),
                  icon: const Icon(PhosphorIconsFill.chatCircle),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(booking['pickupAddress'] ?? '', style: AppTextStyles.bodyMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

