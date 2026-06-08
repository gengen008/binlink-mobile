import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show MapLibreMapController, CameraUpdate, LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
import '../screens/payment_screen.dart';

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


  void _startBookingFlow() {
    if (widget.myPos == null) return;
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

    final address = await PlacesService.reverseGeocode(
        _pickupPosition!.latitude, _pickupPosition!.longitude);
    
    if (mounted) {
      setState(() {
        _currentAddress = address ?? 'Fetching address...';
        _sheetState = HomeSheetState.addressSelection;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(_pickupPosition!.latitude, _pickupPosition!.longitude), 16.5),
      );
    }
  }

  Future<void> _onAddressConfirmed(String address) async {
    final prov = context.read<HouseholdProvider>();
    
    // Choose payment method
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PaymentMethodPicker(),
    );

    if (method == null) return; 

    if (method == 'MOMO') {
      final booking = await prov.createBooking(
        binSize: _selectedBinSize ?? 'SMALL',
        extraBags: _extraBags,
        pickupAddress: address,
        pickupLat: _pickupPosition!.latitude,
        pickupLng: _pickupPosition!.longitude,
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
      pickupLat: _pickupPosition!.latitude,
      pickupLng: _pickupPosition!.longitude,
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
                onMenuTap: () => Scaffold.of(context).openDrawer(),
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
              icon: PhosphorIconsRegular.arrowLeft,
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
        return ServiceSelectionSheet(
          onServiceSelected: _onServiceSelected,
          onCancel: _cancelBooking,
        );
      case HomeSheetState.addressSelection:
        return AddressSelectionSheet(
          currentAddress: _currentAddress,
          onAddressConfirmed: _onAddressConfirmed,
          onCancel: _cancelBooking,
        );
      case HomeSheetState.searching:
        return _SearchingSheet();
      case HomeSheetState.tracking:
        return active != null ? _TrackingBottomSheet(booking: active) : const SizedBox();
    }
  }
}

// ── Components ──────────────────────────────────────────────────────────

class _TopSearchPill extends StatelessWidget {
  const _TopSearchPill({required this.onMenuTap, required this.onSearchTap});
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap,
            child: const Icon(PhosphorIconsRegular.list, size: 24, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Text(
                "Ready for a pickup?",
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ),
          Image.asset(AppAssets.search, width: 24, height: 24, color: AppColors.primary),
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
  final VoidCallback onRequestNow;
  final VoidCallback onSchedule;
  final VoidCallback onShowTracking;
  final List<Map<String, dynamic>> savedAddresses;
  final ValueChanged<Map<String, dynamic>> onAddressTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 3D Categories ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CategoryCardV4(image: AppAssets.bin3d, label: 'Household', onTap: onRequestNow),
              _CategoryCardV4(image: AppAssets.truck3d, label: 'Construction', onTap: onRequestNow),
              _CategoryCardV4(image: AppAssets.recycleBin, label: 'Recycling', onTap: onRequestNow),
              _CategoryCardV4(image: AppAssets.leaf, label: 'Organic', onTap: onRequestNow),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
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
                        icon: PhosphorIconsFill.calendar,
                        title: "Schedule",
                        subtitle: "Plan ahead",
                        color: AppColors.surface,
                        onTap: onSchedule,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionBtnV4(
                        icon: PhosphorIconsFill.lightning,
                        title: "Request",
                        subtitle: "Instant",
                        color: AppColors.primaryLight,
                        textColor: AppColors.primary,
                        onTap: onRequestNow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // ── Saved Addresses Section ──
                const Divider(),
                const SizedBox(height: 16),
                if (savedAddresses.isEmpty)
                  Row(
                    children: [
                      const Icon(PhosphorIconsFill.mapPin, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Saved Addresses", style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
                            Text("No addresses saved yet", style: AppTextStyles.label.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIconsRegular.caretRight, color: AppColors.textMuted),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Quick Pickup", style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      ...savedAddresses.take(3).map((a) => ListTile(
                        onTap: () => onAddressTap(a),
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(PhosphorIconsFill.mapPin, size: 18),
                        ),
                        title: Text(a['label'], style: AppTextStyles.h4),
                        subtitle: Text(a['address'], style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16),
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
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
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
            const Icon(PhosphorIconsRegular.caretRight, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SearchingSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchingRadarWidget(radius: 40, ringColor: AppColors.primary),
          const SizedBox(height: 32),
          Text('Matching with Collector', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('This usually takes less than a minute.', style: AppTextStyles.bodySmall),
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
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(PhosphorIconsFill.truck, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(Fmt.statusLabel(status), style: AppTextStyles.h2.copyWith(color: AppColors.primary))),
            ],
          ),
          const SizedBox(height: 32),
          if (booking['collector'] != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surface,
                  child: Text(Fmt.initials(booking['collector']['fullName']), style: AppTextStyles.h3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['collector']['fullName'] ?? 'Collector', style: AppTextStyles.h3),
                      Text(
                        booking['collector']['vehiclePlate'] != null
                            ? "Vehicle #${booking['collector']['vehiclePlate']}"
                            : "Collector Vehicle",
                        style: AppTextStyles.label,
                      ),
                    ],
                  ),
                ),
                _RoundIconBtn(icon: PhosphorIconsFill.phone, onTap: () => launchUrl(Uri.parse('tel:${booking['collector']['phone'] ?? ''}'))),
                const SizedBox(width: 12),
                _RoundIconBtn(icon: PhosphorIconsFill.chatCircle, onTap: () => showChatSheet(context, bookingId: booking['id'], myRole: 'HOUSEHOLD')),
              ],
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(booking['pickupAddress'] ?? '', style: AppTextStyles.bodyMedium)),
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
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
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
                      color: isSelected ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                    ),
                    child: Column(
                      children: [
                        Text(label, style: AppTextStyles.h4.copyWith(color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                        Text(hours, style: AppTextStyles.label.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'date': _selectedDate, 'timePreference': _timePreference}),
              child: const Text('Confirm Schedule'),
            ),
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
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
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
            icon: PhosphorIconsFill.money,
            onTap: () => Navigator.pop(context, 'CASH'),
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            label: 'Mobile Money',
            icon: PhosphorIconsFill.phone,
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
      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 18),
    );
  }
}
