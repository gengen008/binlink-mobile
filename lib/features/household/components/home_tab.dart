import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show MapLibreMapController, CameraUpdate, LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
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
    final pos = _pickupPosition;
    if (pos == null) return;

    setState(() {
      _selectedCategory = category;
      _selectedBinSize = binSize;
      _extraBags = extraBags;
    });

    final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);

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
    final pos = _pickupPosition;
    if (pos == null) return;

    try {
      final prov = context.read<HouseholdProvider>();

      final method = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const _PaymentMethodPicker(),
      );

      if (method == null) return;

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

        // ── Collector Count Pill (Bolt/Uber-style) ──
        if (_sheetState == HomeSheetState.idle && prov.onlineCollectors.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 88,
            left: 20,
            child: FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: _CollectorCountPill(count: prov.onlineCollectors.length),
            ),
          ),

        // ── Back Button (When Booking) ──
        if (_sheetState != HomeSheetState.idle)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: _FloatingCircularBtn(
              icon: PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
              onTap: _cancelBooking,
            ),
          ),

        // ── Locate Me ──
        Positioned(
          bottom: _sheetState == HomeSheetState.idle ? (active != null ? 350 : 250) : 420,
          right: 20,
          child: _FloatingCircularBtn(
            icon: PhosphorIcons.navigationArrow(PhosphorIconsStyle.fill),
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

    Widget? progressHeader;
    if ([HomeSheetState.serviceSelection, HomeSheetState.addressSelection].contains(_sheetState)) {
      final step = _sheetState == HomeSheetState.serviceSelection ? 1 : 2;
      progressHeader = Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          onAddressTap: (a) {
            final lat = (a['lat'] as num?)?.toDouble();
            final lng = (a['lng'] as num?)?.toDouble();
            if (lat == null || lng == null) return;
            setState(() {
              _pickupPosition = ll.LatLng(lat, lng);
              _currentAddress = a['address'] as String? ?? '';
              _sheetState = HomeSheetState.serviceSelection;
            });
          },
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
      child: isCompleted ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 8, color: Colors.white) : null,
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold), size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Text(
                "Where to collect from?",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircularBtn extends StatelessWidget {
  const _FloatingCircularBtn({this.icon, required this.onTap});
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, size: 24, color: AppColors.textPrimary),
      ),
    );
  }
}

class _IdleBottomSheet extends StatelessWidget {
  const _IdleBottomSheet({
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
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),

            if (activeBooking != null) ...[
              _ActiveBannerV4(booking: activeBooking!, onTap: onShowTracking),
              const SizedBox(height: 24),
            ],

            Text("Ready for pickup?", style: AppTextStyles.h2),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionBtnV4(
                    icon: PhosphorIcons.calendarPlus(PhosphorIconsStyle.fill),
                    title: "Schedule",
                    color: AppColors.surface,
                    borderColor: AppColors.border,
                    onTap: onSchedule,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionBtnV4(
                    icon: PhosphorIcons.truck(PhosphorIconsStyle.fill),
                    title: "Request Now",
                    color: AppColors.primary,
                    textColor: Colors.white,
                    onTap: () => onRequestNow(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ── Saved Addresses Section ──
            if (savedAddresses.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text("Recent Locations", style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              ...savedAddresses.take(2).map((a) => ListTile(
                onTap: () => onAddressTap(a),
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill), size: 20, color: AppColors.textPrimary),
                ),
                title: Text(a['label'], style: AppTextStyles.title.copyWith(fontSize: 16)),
                subtitle: Text(a['address'], style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ]
          ],
        ),
      ),
    );
  }
}

class _ActionBtnV4 extends StatelessWidget {
  const _ActionBtnV4({
    required this.icon,
    required this.title,
    required this.color,
    this.textColor,
    this.borderColor,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(24),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor ?? AppColors.textPrimary, size: 28),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.h4.copyWith(color: textColor ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ActiveBannerV4 extends StatelessWidget {
  const _ActiveBannerV4({required this.booking, required this.onTap});
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
              child: Icon(PhosphorIcons.truck(PhosphorIconsStyle.fill), color: Colors.white, size: 24),
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
            Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), color: Colors.white),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SearchingRadarWidget(radius: 80, ringColor: AppColors.primary),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: Icon(PhosphorIcons.truck(PhosphorIconsStyle.fill), color: AppColors.primary, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Finding your collector', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Searching... $_seconds s', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          AppButton(
            label: 'Cancel Request',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              final prov = context.read<HouseholdProvider>();
              final activeId = prov.activeBooking?['id'];
              if (activeId != null) prov.cancelBooking(activeId);
              widget.onCancel();
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), shape: BoxShape.circle),
                child: Icon(PhosphorIcons.truck(PhosphorIconsStyle.fill), color: AppColors.primary, size: 24),
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
                      radius: 28,
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
                        child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), color: Colors.white, size: 12),
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
                          Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), color: AppColors.warning, size: 14),
                          const SizedBox(width: 4),
                          Text(collector['rating']?.toString() ?? '5.0', style: AppTextStyles.small.copyWith(color: AppColors.textPrimary)),
                          const SizedBox(width: 12),
                          Text(collector['vehiclePlate'] ?? 'No Plate', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                _RoundIconBtn(icon: PhosphorIcons.phone(PhosphorIconsStyle.fill), onTap: () => launchUrl(Uri.parse('tel:${collector['phone'] ?? ''}'))),
                const SizedBox(width: 12),
                _RoundIconBtn(icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.fill), onTap: () => showChatSheet(context, bookingId: booking['id'], myRole: 'HOUSEHOLD')),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill), color: AppColors.textMuted, size: 20),
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
          color: AppColors.background, 
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
            icon: PhosphorIcons.money(PhosphorIconsStyle.fill),
            onTap: () => Navigator.pop(context, 'CASH'),
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            label: 'Mobile Money',
            icon: PhosphorIcons.deviceMobile(PhosphorIconsStyle.fill),
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
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
      title: Text(label, style: AppTextStyles.h4),
      trailing: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 18),
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
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        fontSize: 10,
      ),
    );
  }
}

/// Bolt/Uber-style pill showing how many collectors are live on the map.
class _CollectorCountPill extends StatelessWidget {
  const _CollectorCountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'collector' : 'collectors'} nearby',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
