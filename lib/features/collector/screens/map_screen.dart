import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/stats_row.dart';
import 'active_pickup_screen.dart';
import 'earnings_screen.dart';
import 'pickups_screen.dart';
import 'vehicle_details_screen.dart';
import 'collector_notifications_screen.dart';
import 'collector_help_screen.dart';
import 'collector_privacy_screen.dart';
import 'collector_edit_profile_screen.dart';

class CollectorMapScreen extends StatefulWidget {
  const CollectorMapScreen({super.key});

  @override
  State<CollectorMapScreen> createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  LatLng _pos = const LatLng(5.6037, -0.1870);
  int _tab = 0;
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
    // Fast first pin — last known position is instant (no GPS wait)
    final last = await LocationService.getLastKnownPosition();
    if (last != null && mounted) {
      setState(() => _pos = LatLng(last.latitude, last.longitude));
    }

    // Accurate fix — runs in parallel, updates marker when ready
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _pos = LatLng(pos.latitude, pos.longitude));
    }

    if (mounted) await context.read<CollectorProvider>().loadDashboard();

    // Live updates — keep truck marker in sync as collector moves
    _posSub = LocationService.getPositionStream().listen((p) {
      if (mounted) setState(() => _pos = LatLng(p.latitude, p.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _MapTab(pos: _pos),
          const PickupsScreen(),
          const EarningsScreen(),
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
              icon: PhosphorIconsRegular.mapTrifold,
              iconFill: PhosphorIconsFill.mapTrifold,
              label: 'Map',      index: 0, current: current, onTap: onTap,
            ),
            _NavItem(
              icon: PhosphorIconsRegular.clipboardText,
              iconFill: PhosphorIconsFill.clipboardText,
              label: 'Pickups',  index: 1, current: current, onTap: onTap,
            ),
            _NavItem(
              icon: PhosphorIconsRegular.coins,
              iconFill: PhosphorIconsFill.coins,
              label: 'Earnings', index: 2, current: current, onTap: onTap,
            ),
            _NavItem(
              icon: PhosphorIconsRegular.user,
              iconFill: PhosphorIconsFill.user,
              label: 'Profile',  index: 3, current: current, onTap: onTap,
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
                width: sel ? 36 : 0, height: sel ? 4 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(sel ? iconFill : icon,
                  color: sel ? Theme.of(context).primaryColor : AppColors.muted, size: 22),
              const SizedBox(height: 3),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: sel ? Theme.of(context).primaryColor : AppColors.muted,
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

// ── MAP TAB ───────────────────────────────────────────────────────────────────

class _MapTab extends StatefulWidget {
  const _MapTab({required this.pos});
  final LatLng pos;

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final MapController _mapCtrl = MapController();

  Future<void> _locateMe() async {
    HapticFeedback.lightImpact();
    _mapCtrl.move(widget.pos, 15.5);
  }

  @override
  void didUpdateWidget(_MapTab old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapCtrl.move(widget.pos, 14.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov         = context.watch<CollectorProvider>();
    final user         = context.watch<AuthProvider>().user;
    final currentLoad  = user?.currentLoadKg ?? 0.0;
    final maxCapacity  = user?.maxCapacityKg ?? 500.0;
    final active       = prov.currentActivePickup;

    final mapMarkers = [
      Marker(
        point: widget.pos,
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: (prov.isOnline ? AppColors.success : AppColors.danger)
                .withAlpha(50),
            shape: BoxShape.circle,
            border: Border.all(
              color: prov.isOnline ? AppColors.success : AppColors.danger,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (prov.isOnline ? AppColors.success : AppColors.danger)
                    .withAlpha(80),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            PhosphorIconsFill.truck,
            color: AppColors.white,
            size: 24,
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        // Full-screen map
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: widget.pos,
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: kMapTileUrl,
              subdomains: kMapTileSubdomains,
              userAgentPackageName: 'com.binlink.collector',
              maxZoom: 20,
            ),
            MarkerLayer(markers: mapMarkers),
          ],
        ),

        // Top UI overlay — Positioned so it only takes natural height, never covers map
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.deepOcean.withAlpha(230),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Online status dot
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: prov.isOnline
                                    ? AppColors.success
                                    : AppColors.muted,
                                shape: BoxShape.circle,
                                boxShadow: prov.isOnline
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppColors.success.withAlpha(80),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              prov.isOnline ? 'Online — Accepting jobs' : 'Offline',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                color: prov.isOnline
                                    ? AppColors.success
                                    : AppColors.muted,
                              ),
                            ),
                            // Capacity indicator pill
                            if (prov.isOnline && currentLoad > 0) ...[
                              const SizedBox(width: 8),
                              Builder(builder: (ctx) {
                                final pct = maxCapacity > 0
                                    ? (currentLoad / maxCapacity).clamp(0.0, 1.0)
                                    : 0.0;
                                final color = pct < 0.7
                                    ? AppColors.success
                                    : pct < 0.9
                                        ? AppColors.warning
                                        : AppColors.danger;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: color.withAlpha(80)),
                                  ),
                                  child: Text(
                                    '${(pct * 100).toStringAsFixed(0)}% full',
                                    style: AppTextStyles.caption.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Online toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        prov.toggleOnline();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56, height: 44,
                        decoration: BoxDecoration(
                          gradient: prov.isOnline
                              ? const LinearGradient(
                                  colors: [Color(0xFF16A34A), AppColors.success],
                                )
                              : null,
                          color: prov.isOnline
                              ? null
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: prov.isOnline
                                ? AppColors.success
                                : AppColors.border,
                          ),
                          boxShadow: prov.isOnline
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withAlpha(60),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            prov.isOnline
                                ? PhosphorIconsFill.power
                                : PhosphorIconsRegular.power,
                            color: prov.isOnline
                                ? AppColors.white
                                : AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Active pickup banner
              if (active != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => ActivePickupScreen(booking: active),
                        )),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withAlpha(180),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(PhosphorIconsFill.truck,
                                color: AppColors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active Pickup',
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.white,
                                    )),
                                Text(
                                  active['pickupAddress'] as String? ?? '',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.iceBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(PhosphorIconsRegular.arrowRight,
                              color: AppColors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ), // end Positioned top overlay

        // Locate-me FAB
        Positioned(
          right: 16,
          bottom: prov.pendingRequests.isNotEmpty ? 216 : 80,
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
              child: const Icon(PhosphorIconsRegular.crosshair,
                  color: AppColors.skyBlue, size: 22),
            ),
          ),
        ),

        // Pending request cards (with countdown)
        if (prov.pendingRequests.isNotEmpty && prov.isOnline)
          Positioned(
            left: 0, right: 0, bottom: 16,
            child: _PendingRequestsList(
              requests: prov.pendingRequests,
              onAccepted: (booking) => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => ActivePickupScreen(booking: booking),
                  )),
            ),
          ),
      ],
    );
  }
}

// ── Pending request card with countdown timer ─────────────────────────────────

class _PendingRequestsList extends StatelessWidget {
  const _PendingRequestsList({
    required this.requests,
    required this.onAccepted,
  });
  final List<Map<String, dynamic>> requests;
  final ValueChanged<Map<String, dynamic>> onAccepted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: PageView.builder(
        padEnds: false,
        controller: PageController(viewportFraction: 0.9),
        itemCount: requests.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _RequestCard(booking: requests[i], onAccepted: onAccepted),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.booking, required this.onAccepted});
  final Map<String, dynamic> booking;
  final ValueChanged<Map<String, dynamic>> onAccepted;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  static const _kCountdown = 30;
  int _remaining = _kCountdown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        final prov = context.read<CollectorProvider>();
        prov.declineRequest(widget.booking['id'] as String);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request expired'),
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov    = context.read<CollectorProvider>();
    final binSize = widget.booking['binSize'] as String? ?? '';
    final address = widget.booking['pickupAddress'] as String? ?? '';
    final amount  = (widget.booking['totalAmount'] as num?)?.toDouble() ?? 0;
    final cat     = widget.booking['wasteCategory'] as String?;
    final progress = _remaining / _kCountdown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepOcean.withAlpha(240),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              // New request label
              Builder(builder: (ctx) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(ctx).primaryColor.withAlpha(60)),
                ),
                child: Text('New Request',
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(ctx).primaryColor,
                      fontWeight: FontWeight.w700,
                    )),
              )),
              const Spacer(),
              Text(Fmt.currency(amount),
                  style: AppTextStyles.mono.copyWith(color: AppColors.iceBlue)),
              const SizedBox(width: 12),
              // Countdown ring
              SizedBox(
                width: 36, height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      color: progress > 0.4
                          ? AppColors.steelBlue
                          : AppColors.danger,
                      backgroundColor: AppColors.border,
                    ),
                    Text(
                      '$_remaining',
                      style: AppTextStyles.caption.copyWith(
                        color: progress > 0.4
                            ? AppColors.white
                            : AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Address
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin,
                  color: AppColors.muted, size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Chips
          Row(
            children: [
              _SmallChip(label: Fmt.binSizeLabel(binSize).split(' ').first),
              if (cat != null) ...[
                const SizedBox(width: 6),
                _SmallChip(label: cat.replaceAll('_', ' ')),
              ],
            ],
          ),
          const Spacer(),

          // Accept / Decline
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => prov.declineRequest(
                      widget.booking['id'] as String),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withAlpha(60)),
                    ),
                    child: Center(
                      child: Text('Decline',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.danger,
                            fontSize: 13,
                          )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Builder(builder: (ctx) => GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    _timer?.cancel();
                    final prov = context.read<CollectorProvider>();
                    final ok = await prov
                        .acceptRequest(widget.booking['id'] as String);
                    if (ok) {
                      final pickup = prov.currentActivePickup;
                      if (pickup != null) widget.onAccepted(pickup);
                    }
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(ctx).primaryColor,
                          Theme.of(ctx).primaryColor.withAlpha(200),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(ctx).primaryColor.withAlpha(80),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('Accept Pickup',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontSize: 13,
                          )),
                    ),
                  ),
                )),
              ),
            ],
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
                  color: sel ? AppColors.warning.withAlpha(30) : AppColors.deepOcean,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppColors.warning : AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(lang,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: sel ? AppColors.warning : AppColors.textPrimary,
                          )),
                    ),
                    if (sel)
                      const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.warning, size: 18),
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
    final prov = context.watch<CollectorProvider>();
    final user = auth.user;

    // Collector stats
    final earned = prov.completedPickups.fold<double>(
        0, (s, b) => s + ((b['totalAmount'] as num?)?.toDouble() ?? 0) * 0.9);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              // Avatar + name
              Stack(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withAlpha(160),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withAlpha(80),
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
                  // Online status ring
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: prov.isOnline
                            ? AppColors.success
                            : AppColors.muted,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.deepOcean, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(user?.fullName ?? 'Collector', style: AppTextStyles.h3),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(user!.email!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    )),
              ],
              const SizedBox(height: 8),

              // Rating row
              if (user != null && user.rating > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (i) => Icon(
                          i < user.rating.floor()
                              ? PhosphorIconsFill.star
                              : PhosphorIconsRegular.star,
                          color: AppColors.warning,
                          size: 16,
                        )),
                    const SizedBox(width: 6),
                    Text(
                      '${user.rating.toStringAsFixed(1)} (${user.totalPickups} jobs)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Stats row
              StatsRow(
                totalPickups: prov.totalPickups,
                totalSpent: earned,
                kgRecycled: prov.totalPickups * 18.0,
              ),

              const SizedBox(height: 20),

              // Vehicle chip
              if (user?.vehicleType != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsFill.truck,
                          color: AppColors.skyBlue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vehicle',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.muted,
                                )),
                            Text(
                              '${user!.vehicleType!.replaceAll('_', ' ')} • ${user.vehiclePlate ?? 'No plate'}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => const VehicleDetailsScreen(),
                            )),
                        child: const Icon(PhosphorIconsRegular.pencilSimple,
                            color: AppColors.muted, size: 16),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Menu
              _MenuSection(
                title: 'Account',
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.userCircle,
                    label: 'Edit Profile',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const CollectorEditProfileScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.truck,
                    label: 'Vehicle Details',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const VehicleDetailsScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.coins,
                    label: 'Earnings & Wallet',
                    onTap: () {/* navigate to earnings screen */},
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.bell,
                    label: 'Notifications',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const CollectorNotificationsScreen(),
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _MenuSection(
                title: 'Support',
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.headset,
                    label: 'Help & Support',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const CollectorHelpScreen(),
                        )),
                  ),
                  _MenuItem(
                    icon: PhosphorIconsRegular.shieldCheck,
                    label: 'Privacy Policy',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const CollectorPrivacyScreen(),
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 12),

              // Preferences — dark mode + language
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text('Preferences',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(PhosphorIconsRegular.moon,
                                color: AppColors.warning, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Dark Mode', style: AppTextStyles.bodyMedium),
                          ),
                          Consumer<ThemeProvider>(
                            builder: (_, tp, __) => Switch(
                              value: tp.isDark,
                              onChanged: tp.setDark,
                              activeThumbColor: AppColors.warning,
                              activeTrackColor: AppColors.warning.withAlpha(80),
                              inactiveTrackColor: AppColors.border,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _pickLanguage(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            const Expanded(
                              child: Text('Language', style: AppTextStyles.bodyMedium),
                            ),
                            Text(context.watch<AppStringsProvider>().langCode,
                                style: AppTextStyles.body.copyWith(
                                    color: AppColors.muted, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(PhosphorIconsRegular.caretRight,
                                color: AppColors.muted, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _MenuSection(
                title: 'App',
                items: [
                  _MenuItem(
                    icon: PhosphorIconsRegular.signOut,
                    label: 'Sign Out',
                    color: AppColors.danger,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          title: const Text('Sign Out',
                              style: AppTextStyles.h3),
                          content: Text(
                            'Are you sure you want to sign out?',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.muted,
                                  )),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Sign Out',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.danger,
                                  )),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('BinLink Collector v3.0.0',
                  style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared profile widgets ────────────────────────────────────────────────────

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
              final item   = items[i];
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (item.color ?? AppColors.skyBlue)
                                  .withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon,
                                color: item.color ?? AppColors.skyBlue,
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: item.color ?? AppColors.textPrimary,
                                )),
                          ),
                          const Icon(PhosphorIconsRegular.caretRight,
                              color: AppColors.muted, size: 16),
                        ],
                      ),
                    ),
                  ),
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

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.steelBlue.withAlpha(40)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.steelBlue,
            fontSize: 11,
          )),
    );
  }
}
