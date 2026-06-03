import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/l10n/strings.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/stats_row.dart';
import '../../../shared/widgets/collector_bottom_sheet.dart';
import '../../../shared/widgets/location_search_sheet.dart';
import 'book_screen.dart';
import 'tracking_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';
import 'saved_addresses_screen.dart';

class HouseholdHomeScreen extends StatefulWidget {
  const HouseholdHomeScreen({super.key});

  @override
  State<HouseholdHomeScreen> createState() => _HouseholdHomeScreenState();
}

class _HouseholdHomeScreenState extends State<HouseholdHomeScreen> {
  LatLng _myPos = const LatLng(5.6037, -0.1870);
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _myPos = LatLng(pos.latitude, pos.longitude));
    }
    if (!mounted) return;
    await context.read<HouseholdProvider>().loadBookings();
    if (!mounted) return;
    await context.read<HouseholdProvider>().loadOnlineCollectors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(myPos: _myPos),
          _HistoryTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepOcean,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: PhosphorIconsRegular.house,
              iconFill: PhosphorIconsFill.house,
              label: s.home, index: 0, current: current, onTap: onTap,
            ),
            _NavItem(
              icon: PhosphorIconsRegular.clockCounterClockwise,
              iconFill: PhosphorIconsFill.clockCounterClockwise,
              label: s.history, index: 1, current: current, onTap: onTap,
            ),
            _NavItem(
              icon: PhosphorIconsRegular.user,
              iconFill: PhosphorIconsFill.user,
              label: s.profile, index: 2, current: current, onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon, required this.iconFill, required this.label,
    required this.index, required this.current, required this.onTap,
  });
  final IconData icon;
  final IconData iconFill;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final sel = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: sel ? 36 : 0,
                height: sel ? 4 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(sel ? iconFill : icon,
                  color: sel ? AppColors.steelBlue : AppColors.muted, size: 22),
              const SizedBox(height: 3),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: sel ? AppColors.steelBlue : AppColors.muted,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HOME TAB ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.myPos});
  final LatLng myPos;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final MapController _mapCtrl = MapController();

  @override
  void didUpdateWidget(_HomeTab old) {
    super.didUpdateWidget(old);
    if (old.myPos != widget.myPos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapCtrl.move(widget.myPos, 14.0);
      });
    }
  }

  Future<void> _locateMe() async {
    HapticFeedback.lightImpact();
    _mapCtrl.move(widget.myPos, 15.5);
  }

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<HouseholdProvider>();
    final auth   = context.watch<AuthProvider>();
    final active = prov.activeBooking;

    // Build markers for flutter_map
    final mapMarkers = <Marker>[
      // My location
      Marker(
        point: widget.myPos,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.steelBlue.withAlpha(50),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.steelBlue, width: 2.5),
          ),
          child: const Icon(PhosphorIconsFill.mapPin,
              color: AppColors.white, size: 22),
        ),
      ),
      // Online collectors
      ...prov.onlineCollectors.map((c) {
        final lat = (c['lastLat'] as num?)?.toDouble();
        final lng = (c['lastLng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        return Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              showCollectorSheet(
                context, c,
                onRequestPickup: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => const BookScreen(mode: 'immediate'),
                    )),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 2.5),
              ),
              child: const Icon(PhosphorIconsFill.truck,
                  color: AppColors.white, size: 22),
            ),
          ),
        );
      }).whereType<Marker>(),
    ];

    return Container(
      color: AppColors.midnightNavy,
      child: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: widget.myPos,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: kMapTileUrl,
                  subdomains: kMapTileSubdomains,
                  userAgentPackageName: 'com.binlink.eco',
                  maxZoom: 20,
                ),
                MarkerLayer(markers: mapMarkers),
              ],
            ),
          ),

          // ── Top overlay: header + search bar ──────────────────────
          // Positioned so it only takes its natural height, never covers the map.
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Greeting header (glass card)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.deepOcean.withAlpha(230),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()}, 👋',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                auth.user?.fullName?.split(' ').first ??
                                    'Welcome',
                                style: AppTextStyles.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Online collectors chip
                        if (prov.onlineCollectors.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.success.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${prov.onlineCollectors.length} ${S.of(context).nearbyCount}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(width: 8),
                        const SizedBox(width: 10),
                        // Notification bell
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen())),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.bell,
                              color: AppColors.skyBlue,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Search bar pill — opens Places search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final result = await showLocationSearch(
                        context,
                        lat: widget.myPos.latitude,
                        lng: widget.myPos.longitude,
                      );
                      if (result != null && context.mounted) {
                        _mapCtrl.move(LatLng(result.lat, result.lng), 16.0);
                      }
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.deepOcean.withAlpha(230),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsRegular.magnifyingGlass,
                              color: AppColors.steelBlue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(S.of(context).searchAreaLandmark,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.muted,
                                )),
                          ),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.steelBlue.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(PhosphorIconsRegular.mapPin,
                                color: AppColors.steelBlue, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ), // end Positioned top overlay

          // ── Locate-me FAB ──────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: active != null ? 200 : 168,
            child: GestureDetector(
              onTap: _locateMe,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.deepOcean,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  PhosphorIconsRegular.crosshair,
                  color: AppColors.skyBlue,
                  size: 22,
                ),
              ),
            ),
          ),

          // ── Bottom: active banner OR split CTA ─────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: active != null
                    ? _ActiveBookingBanner(booking: active)
                    : _SplitCta(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Active booking banner ─────────────────────────────────────────────────────

class _ActiveBookingBanner extends StatefulWidget {
  const _ActiveBookingBanner({required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<_ActiveBookingBanner> createState() => _ActiveBookingBannerState();
}

class _ActiveBookingBannerState extends State<_ActiveBookingBanner> {
  static const _cancellable = {
    'PENDING', 'SEARCHING', 'ASSIGNED',
    'ACCEPTED', 'EN_ROUTE', 'ON_THE_WAY', 'ARRIVED',
  };

  Color _statusColor(String status) => AppColors.statusColor(status);

  Future<void> _showCancelDialog() async {
    String? selectedReason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) {
          final s = S.of(ctx2);
          final reasons = s.cancelReasons;
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(s.cancelConfirm, style: AppTextStyles.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tellUsWhyCancel,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...reasons.map((reason) {
                  final sel = reason == selectedReason;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedReason = reason),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.danger.withAlpha(15)
                            : AppColors.deepOcean,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? AppColors.danger : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(reason,
                                style: AppTextStyles.body.copyWith(
                                  color: sel
                                      ? AppColors.danger
                                      : AppColors.textPrimary,
                                  fontSize: 13,
                                )),
                          ),
                          if (sel)
                            const Icon(PhosphorIconsFill.checkCircle,
                                color: AppColors.danger, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.keepBooking,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.muted)),
              ),
              TextButton(
                onPressed: selectedReason != null
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(s.yesCancel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selectedReason != null
                          ? AppColors.danger
                          : AppColors.muted,
                    )),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final prov = context.read<HouseholdProvider>();
      final ok = await prov.cancelBooking(
        widget.booking['id'] as String,
        reason: selectedReason,
      );
      if (mounted) {
        final s = S.read(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? s.bookingCancelled
                : 'Could not cancel — please try again'),
            backgroundColor: ok ? AppColors.success : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'] as String? ?? 'PENDING';
    final color  = _statusColor(status);
    final canCancel = _cancellable.contains(status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                builder: (_) => TrackingScreen(bookingId: widget.booking['id'] as String),
              )),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepOcean.withAlpha(240),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(PhosphorIconsFill.trashSimple,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Fmt.statusLabel(status),
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(S.of(context).tapToTrack,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                          )),
                    ],
                  ),
                ),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsRegular.arrowRight,
                      color: AppColors.steelBlue, size: 18),
                ),
              ],
            ),
          ),
        ),

        if (canCancel) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showCancelDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withAlpha(50)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.xCircle,
                      color: AppColors.danger, size: 16),
                  const SizedBox(width: 6),
                  Text(S.of(context).cancelBooking,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Split CTA ─────────────────────────────────────────────────────────────────

class _SplitCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Request Now
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const BookScreen(mode: 'immediate'),
                  ));
            },
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.steelBlue, AppColors.deepOcean],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.steelBlue.withAlpha(100)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.steelBlue.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(PhosphorIconsFill.lightning,
                          color: AppColors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context).requestNow,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white,
                              )),
                          Text(S.of(context).arrival15min,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.iceBlue,
                                fontSize: 10,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Schedule
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const BookScreen(mode: 'scheduled'),
                  ));
            },
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.deepOcean.withAlpha(230),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.skyBlue.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.skyBlue.withAlpha(60)),
                      ),
                      child: const Icon(PhosphorIconsRegular.calendarBlank,
                          color: AppColors.skyBlue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context).schedule,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white,
                              )),
                          Text(S.of(context).pickDate,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted,
                                fontSize: 10,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── HISTORY TAB ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  static const _cancellable = {'PENDING', 'ACCEPTED', 'EN_ROUTE', 'ARRIVED'};

  @override
  Widget build(BuildContext context) {
    final prov          = context.watch<HouseholdProvider>();
    final allBookings   = prov.allBookings;
    final completed     = prov.completedBookings;
    final subscriptions = prov.subscriptionBookings;

    // Stats
    final totalSpent = completed.fold<double>(
        0, (s, b) => s + ((b['totalAmount'] as num?)?.toDouble() ?? 0));
    const kgPerPickup = 15.0;
    final kgRecycled  = completed.length * kgPerPickup;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).history, style: AppTextStyles.h2),
                      Text('${allBookings.length} ${S.of(context).totalPickupsLabel}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  const Spacer(),
                  if (prov.loading)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.steelBlue,
                      ),
                    ),
                ],
              ),
            ),

            // Stats row + Impact
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StatsRow(
                  totalPickups: completed.length,
                  totalSpent: totalSpent,
                  kgRecycled: kgRecycled,
                ),
              ),
              const SizedBox(height: 12),
              _ImpactCard(kgRecycled: kgRecycled, bookings: completed),
            ],

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // ── Active Subscriptions ──────────────────────────
                  if (subscriptions.isNotEmpty) ...[
                    Text(S.of(context).activeSubscriptionsTitle, style: AppTextStyles.h4),
                    const SizedBox(height: 10),
                    ...subscriptions.map(
                      (b) => _SubscriptionCard(
                        booking: b,
                        onTap: () => _showBookingDetail(context, b),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── All bookings list ─────────────────────────────
                  if (allBookings.isEmpty)
                    _EmptyState(
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      title: S.of(context).noBookingsYet,
                      subtitle: S.of(context).noPickupsYetSub,
                    )
                  else ...[
                    Text(S.of(context).allBookings, style: AppTextStyles.h4),
                    const SizedBox(height: 10),
                    ...List.generate(allBookings.length, (i) {
                      final b = allBookings[i];
                      final status = b['status'] as String? ?? '';
                      final canCancel = _cancellable.contains(status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showBookingDetail(context, b),
                              child: BookingCard(
                                booking: b,
                                showCollector: true,
                              ),
                            ),
                            if (canCancel) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showCancelDialog(context, b),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withAlpha(12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.danger.withAlpha(50)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          PhosphorIconsRegular.xCircle,
                                          color: AppColors.danger,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(S.of(context).cancelBooking,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(
      BuildContext context, Map<String, dynamic> booking) async {
    String? selectedReason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) {
          final s = S.of(ctx2);
          final reasons = s.cancelReasons;
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(s.cancelConfirm, style: AppTextStyles.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tellUsWhyCancel,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...reasons.map((reason) {
                  final sel = reason == selectedReason;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedReason = reason),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.danger.withAlpha(15)
                            : AppColors.deepOcean,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? AppColors.danger : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(reason,
                                style: AppTextStyles.body.copyWith(
                                  color: sel
                                      ? AppColors.danger
                                      : AppColors.textPrimary,
                                  fontSize: 13,
                                )),
                          ),
                          if (sel)
                            const Icon(PhosphorIconsFill.checkCircle,
                                color: AppColors.danger, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.keepBooking,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.muted)),
              ),
              TextButton(
                onPressed: selectedReason != null
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(s.yesCancel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selectedReason != null
                          ? AppColors.danger
                          : AppColors.muted,
                    )),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      final prov = context.read<HouseholdProvider>();
      final ok = await prov.cancelBooking(
        booking['id'] as String,
        reason: selectedReason,
      );
      if (context.mounted) {
        final s = S.read(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? s.bookingCancelled
                : 'Could not cancel — please try again'),
            backgroundColor: ok ? AppColors.success : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showBookingDetail(
      BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(booking: booking),
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.booking, required this.onTap});
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final freq      = booking['frequency'] as String? ?? 'WEEKLY';
    final status    = booking['status'] as String? ?? 'PENDING';
    final address   = booking['pickupAddress'] as String? ?? '';
    final binSize   = booking['binSize'] as String? ?? '';
    final category  = (booking['wasteCategory'] as String?)?.replaceAll('_', ' ') ?? '';

    const freqLabels = {
      'WEEKLY': 'Weekly',
      'BIWEEKLY': 'Every 2 Weeks',
      'MONTHLY': 'Monthly',
    };
    const freqIcons = {
      'WEEKLY': PhosphorIconsRegular.repeat,
      'BIWEEKLY': PhosphorIconsRegular.arrowsCounterClockwise,
      'MONTHLY': PhosphorIconsRegular.calendarCheck,
    };

    final isActive = ['PENDING', 'ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? AppColors.steelBlue.withAlpha(100) : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.steelBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                freqIcons[freq] ?? PhosphorIconsRegular.repeat,
                color: AppColors.steelBlue, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        freqLabels[freq] ?? freq,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isActive ? AppColors.success : AppColors.muted).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : status,
                          style: AppTextStyles.caption.copyWith(
                            color: isActive ? AppColors.success : AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$binSize bin${category.isNotEmpty ? ' · $category' : ''}',
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                  Text(
                    address,
                    style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                color: AppColors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Impact card ────────────────────────────────────────────────────────────

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.kgRecycled, required this.bookings});
  final double kgRecycled;
  final List<Map<String, dynamic>> bookings;

  List<BarChartGroupData> _monthBars() {
    final now    = DateTime.now();
    final counts = <int, int>{};
    for (var i = 0; i < 6; i++) {
      counts[i] = 0;
    }
    for (final b in bookings) {
      final dt = DateTime.tryParse(b['createdAt'] as String? ?? '');
      if (dt == null) continue;
      final monthsAgo = (now.year - dt.year) * 12 + now.month - dt.month;
      if (monthsAgo >= 0 && monthsAgo < 6) {
        counts[5 - monthsAgo] = (counts[5 - monthsAgo] ?? 0) + 1;
      }
    }
    return List.generate(6, (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: (counts[i] ?? 0).toDouble(),
          color: AppColors.steelBlue.withAlpha(counts[i]! > 0 ? 220 : 80),
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ));
  }

  String _monthLabel(int i) {
    final now   = DateTime.now();
    final month = DateTime(now.year, now.month - (5 - i));
    const m = ['J','F','M','A','M','J','J','A','S','O','N','D'];
    return m[(month.month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    final co2   = kgRecycled * 0.5;
    final trees = co2 / 22.0;
    final bars  = _monthBars();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(PhosphorIconsFill.leaf, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Text('Your Environmental Impact', style: AppTextStyles.label),
              ],
            ),
            const SizedBox(height: 14),

            // 3 metric chips
            Row(
              children: [
                _ImpactChip(
                  value: '${kgRecycled.toStringAsFixed(0)} kg',
                  label: 'Waste Diverted',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _ImpactChip(
                  value: '${co2.toStringAsFixed(1)} kg',
                  label: 'CO₂ Saved',
                  color: AppColors.skyBlue,
                ),
                const SizedBox(width: 8),
                _ImpactChip(
                  value: trees >= 1
                      ? trees.toStringAsFixed(1)
                      : '<1',
                  label: 'Trees Eq.',
                  color: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Monthly bar chart
            SizedBox(
              height: 72,
              child: BarChart(
                BarChartData(
                  barGroups: bars,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        getTitlesWidget: (v, _) => Text(
                          _monthLabel(v.toInt()),
                          style: AppTextStyles.caption.copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.mono.copyWith(
              color: color, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(
              fontSize: 9, color: AppColors.muted),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final status    = booking['status'] as String? ?? '';
    final binSize   = booking['binSize'] as String? ?? '';
    final extra     = (booking['extraBags'] as num?)?.toInt() ?? 0;
    final address   = booking['pickupAddress'] as String? ?? '';
    final amount    = (booking['totalAmount'] as num?)?.toDouble() ?? 0;
    final method    = booking['paymentMethod'] as String? ?? '';
    final cat       = booking['wasteCategory'] as String?;
    final collector = booking['collector'] as Map<String, dynamic>?;
    final date      = booking['createdAt'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.deepOcean,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
            const SizedBox(height: 24),

            // Status badge
            Row(
              children: [
                const Text('Booking Details', style: AppTextStyles.h3),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.statusColor(status).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.statusColor(status).withAlpha(80)),
                  ),
                  child: Text(
                    Fmt.statusLabel(status),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.statusColor(status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detail rows
            _DetailRow(
              icon: PhosphorIconsRegular.trashSimple,
              label: 'Bin Size',
              value: Fmt.binSizeLabel(binSize),
            ),
            if (cat != null)
              _DetailRow(
                icon: PhosphorIconsRegular.recycle,
                label: 'Category',
                value: cat.replaceAll('_', ' '),
              ),
            if (extra > 0)
              _DetailRow(
                icon: PhosphorIconsRegular.plus,
                label: 'Extra Bags',
                value: '$extra bag${extra > 1 ? 's' : ''}',
              ),
            _DetailRow(
              icon: PhosphorIconsRegular.mapPin,
              label: 'Address',
              value: address,
            ),
            _DetailRow(
              icon: PhosphorIconsRegular.deviceMobile,
              label: 'Payment',
              value: Fmt.paymentMethodLabel(method),
            ),
            if (collector != null)
              _DetailRow(
                icon: PhosphorIconsRegular.user,
                label: 'Collector',
                value: collector['fullName'] as String? ?? 'Unknown',
              ),
            if (date != null)
              _DetailRow(
                icon: PhosphorIconsRegular.calendarBlank,
                label: 'Date',
                value: Fmt.shortDate(date),
              ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: AppTextStyles.h4),
                Text(Fmt.currency(amount),
                    style: AppTextStyles.monoLg.copyWith(
                      color: AppColors.iceBlue,
                    )),
              ],
            ),

            const SizedBox(height: 24),

            // Download receipt button
            GestureDetector(
              onTap: () => ReceiptService.shareReceipt(booking),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsRegular.downloadSimple,
                        color: AppColors.skyBlue, size: 18),
                    const SizedBox(width: 8),
                    Text('Download Receipt',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.skyBlue,
                        )),
                  ],
                ),
              ),
            ),

            // Rate collector button (COMPLETED + not yet rated)
            if (status == 'COMPLETED' &&
                booking['review'] == null &&
                collector != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showRatingSheet(
                    context, booking['id'] as String, collector),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.steelBlue.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsFill.star, color: AppColors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Rate Your Collector',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Collector rating helpers ───────────────────────────────────────────────

void _showRatingSheet(
  BuildContext ctx,
  String bookingId,
  Map<String, dynamic>? collector,
) {
  showModalBottomSheet(
    context: ctx,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RatingSheet(
      bookingId: bookingId,
      collectorName: collector?['fullName'] as String? ?? 'Collector',
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.bookingId, required this.collectorName});
  final String bookingId;
  final String collectorName;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted  = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    setState(() => _submitting = true);
    try {
      await ApiClient.post('/api/bookings/${widget.bookingId}/rating', {
        'stars': _stars,
        if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
      });
      if (mounted) setState(() { _submitting = false; _submitted = true; });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepOcean,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withAlpha(80)),
          ),
          child: const Icon(PhosphorIconsFill.checkCircle,
              color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Thanks for your feedback!', style: AppTextStyles.h3),
        const SizedBox(height: 6),
        const Text('Your rating helps us improve the service.',
            style: AppTextStyles.caption, textAlign: TextAlign.center),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
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

        const Text('Rate Your Collector', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(
          'How was your experience with ${widget.collectorName}?',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 24),

        // Stars
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      filled ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                      key: ValueKey('star_${i}_$filled'),
                      color: filled ? AppColors.warning : AppColors.border,
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _stars == 0 ? 'Tap to rate'
                : _stars == 1 ? 'Poor'
                : _stars == 2 ? 'Fair'
                : _stars == 3 ? 'Good'
                : _stars == 4 ? 'Very Good'
                : 'Excellent!',
            style: AppTextStyles.label.copyWith(
              color: _stars == 0
                  ? AppColors.muted
                  : _stars >= 4
                      ? AppColors.success
                      : AppColors.warning,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Optional comment
        TextField(
          controller: _commentCtrl,
          style: AppTextStyles.bodyMedium,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Leave a comment (optional)',
            hintStyle: AppTextStyles.caption,
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.steelBlue),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Submit button
        Opacity(
          opacity: _stars > 0 ? 1.0 : 0.45,
          child: GestureDetector(
            onTap: _stars > 0 && !_submitting ? _submit : null,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _stars > 0 ? [
                  BoxShadow(
                    color: AppColors.steelBlue.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ] : null,
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white,
                        ))
                    : const Text('Submit Rating',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    )),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── PROFILE TAB ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  static const _languages = ['English', 'Français'];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final sp = context.read<AppStringsProvider>();
    final current = sp.langCode;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Language / Langue', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            final sel = lang == current;
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, lang),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppColors.steelBlue.withAlpha(30) : AppColors.deepOcean,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppColors.steelBlue : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(lang,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: sel ? AppColors.steelBlue : AppColors.textPrimary,
                          )),
                    ),
                    if (sel)
                      const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.steelBlue, size: 18),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null && picked != current) {
      await sp.setLanguage(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              // ── Avatar section ──────────────────────────────────────
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.steelBlue.withAlpha(80),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            Fmt.initials(user?.fullName),
                            style: AppTextStyles.h2.copyWith(fontSize: 28),
                          ),
                        ),
                      ),
                      // Edit badge
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              )),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.deepOcean, width: 2),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.pencilSimple,
                              color: AppColors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(user?.fullName ?? 'Household', style: AppTextStyles.h3),
                  if (user?.email != null) ...[
                    const SizedBox(height: 4),
                    Text(user!.email!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.steelBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.steelBlue.withAlpha(60)),
                    ),
                    child: Text(S.of(context).householdMember,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.steelBlue,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Info card ───────────────────────────────────────────
              _InfoCard(user: user),

              const SizedBox(height: 16),

              // ── Eco Wallet card ──────────────────────────────────────
              _EcoWalletCard(user: user),

              const SizedBox(height: 16),

              // ── Menu sections ───────────────────────────────────────
              _MenuSection(
                title: S.of(context).account,
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.userCircle,
                    label: S.of(context).editProfile,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.bell,
                    label: S.of(context).notifications,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.mapPin,
                    label: S.of(context).savedAddresses,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const SavedAddressesScreen(),
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _MenuSection(
                title: S.of(context).support,
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.headset,
                    label: S.of(context).helpSupport,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.shieldCheck,
                    label: S.of(context).privacyPolicy,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.files,
                    label: S.of(context).termsOfService,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const TermsScreen(),
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Preferences section ──────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(S.of(context).preferences.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        )),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Dark mode toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.skyBlue.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(PhosphorIconsRegular.moon,
                                    color: AppColors.skyBlue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(S.of(context).darkMode,
                                    style: AppTextStyles.bodyMedium),
                              ),
                              Consumer<ThemeProvider>(
                                builder: (_, tp, __) => Switch(
                                  value: tp.isDark,
                                  onChanged: tp.setDark,
                                  activeThumbColor: AppColors.steelBlue,
                                  activeTrackColor: AppColors.steelBlue.withAlpha(80),
                                  inactiveTrackColor: AppColors.border,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        // Language selector
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _pickLanguage(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.skyBlue.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(PhosphorIconsRegular.globe,
                                      color: AppColors.skyBlue, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(S.of(context).language,
                                      style: AppTextStyles.bodyMedium),
                                ),
                                Text(context.watch<AppStringsProvider>().langCode,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    )),
                                const SizedBox(width: 6),
                                const Icon(PhosphorIconsRegular.caretRight,
                                    color: AppColors.muted, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _MenuSection(
                title: 'App',
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.star,
                    label: 'Rate BinLink',
                    onTap: () => _showRateDialog(context),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.signOut,
                    label: 'Sign Out',
                    color: AppColors.danger,
                    onTap: () => _signOut(context, auth),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('BinLink Eco v3.0.0', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    int stars = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: const Text('Rate BinLink', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enjoying BinLink? Leave us a rating!',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setS(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < stars
                            ? PhosphorIconsFill.star
                            : PhosphorIconsRegular.star,
                        color: AppColors.warning,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.muted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (stars > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('Submit',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.steelBlue)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', style: AppTextStyles.h3),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final memberSince = user?.memberSince != null
        ? Fmt.shortDate(user!.memberSince!)
        : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: PhosphorIconsRegular.phone,
            label: 'Phone',
            value: user?.phone ?? 'Not set',
          ),
          const Divider(height: 1, color: AppColors.border),
          _InfoRow(
            icon: PhosphorIconsRegular.mapPin,
            label: 'Address',
            value: user?.address ?? 'Not set',
          ),
          const Divider(height: 1, color: AppColors.border),
          _InfoRow(
            icon: PhosphorIconsRegular.calendarBlank,
            label: 'Member Since',
            value: memberSince,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ── Eco wallet card ────────────────────────────────────────────────────────

class _EcoWalletCard extends StatelessWidget {
  const _EcoWalletCard({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final pts = user?.ecoPoints ?? 0;
    final kg  = user?.totalKgRecycled ?? 0.0;
    final redeemable = pts ~/ 100; // GHC 5 per 100 pts

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B1A), Color(0xFF0D2137)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsFill.leaf,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eco Wallet', style: AppTextStyles.label.copyWith(
                    color: AppColors.success,
                  )),
                  Text('$pts points earned',
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.textPrimary,
                      )),
                ],
              ),
              const Spacer(),
              if (kg > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${kg.toStringAsFixed(1)} kg',
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.success, fontSize: 14)),
                    Text('recycled', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                  ],
                ),
            ],
          ),
          if (redeemable > 0) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(PhosphorIconsFill.gift,
                    color: AppColors.warning, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You can redeem ${redeemable * 100} pts for GHC ${(redeemable * 5).toStringAsFixed(0)} discount on your next pickup',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Earn 10 pts per recyclable pickup. 100 pts = GHC 5 off.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.skyBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.body.copyWith(
                      color: value == 'Not set'
                          ? AppColors.muted
                          : AppColors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  _MenuTile(item: item),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppColors.textPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (item.color ?? AppColors.skyBlue).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon,
                  color: item.color ?? AppColors.skyBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label,
                  style: AppTextStyles.bodyMedium.copyWith(color: color)),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                color: AppColors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.muted, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
