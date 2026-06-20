import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/household_design_system.dart';
import '../../../shared/components/binlink_map.dart';
import '../providers/household_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late Map<String, dynamic> _booking;
  String _status = 'SEARCHING';
  RealtimeChannel? _supaChannel;

  @override
  void initState() {
    super.initState();
    _booking = Map<String, dynamic>.from(widget.booking);
    _status = (_booking['status'] as String? ?? 'SEARCHING').toUpperCase();
    final bookingId = _booking['id'] as String?;
    if (bookingId != null) {
      context.read<HouseholdProvider>().listenToBooking(bookingId);
      _subscribeRealtime(bookingId);
    }
  }

  void _subscribeRealtime(String bookingId) {
    try {
      _supaChannel = Supabase.instance.client
          .channel('tracking_$bookingId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'booking_status_events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'booking_id',
              value: bookingId,
            ),
            callback: (payload) {
              final s = payload.newRecord['status'] as String?;
              if (s != null && mounted) setState(() => _status = s.toUpperCase());
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _supaChannel?.unsubscribe();
    context.read<HouseholdProvider>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();

    // Mirror status from provider (socket updates)
    final provStatus = (prov.activeBooking?['status'] as String?)?.toUpperCase();
    if (provStatus != null && provStatus != _status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _status = provStatus);
      });
    }

    final pickupLat = (_booking['pickupLat'] as num?)?.toDouble();
    final pickupLng = (_booking['pickupLng'] as num?)?.toDouble();
    final pickupPos = pickupLat != null && pickupLng != null ? ll.LatLng(pickupLat, pickupLng) : null;

    final collectorLat = prov.collectorLat;
    final collectorLng = prov.collectorLng;

    final collector = (prov.activeBooking?['collector'] as Map<String, dynamic>?) ?? (_booking['collector'] as Map<String, dynamic>?);

    final collectorEntry = collectorLat != null && collectorLng != null
        ? <String, dynamic>{
            'id': collector?['id'] ?? 'live-collector',
            'lastLat': collectorLat,
            'lastLng': collectorLng,
            'bearing': 0.0,
            'fullName': collector?['fullName'] ?? 'Collector',
          }
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1821),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────────
          Positioned.fill(
            child: pickupPos != null
                ? BinLinkMap(
                    initialPosition: pickupPos,
                    pickupPosition: pickupPos,
                    collectors: collectorEntry != null ? [collectorEntry] : [],
                    myLocationEnabled: false,
                  )
                : _DarkPlaceholder(status: _status),
          ),

          // ── Top bar ─────────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 14,
            right: 14,
            child: _TopBar(status: _status, onBack: () => Navigator.maybePop(context)),
          ),

          // ── Bottom card ──────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCard(
              booking: _booking,
              status: _status,
              collector: collector,
              onCall: () => _launchCall(collector?['phone'] as String?),
              onCancel: () => _confirmCancel(context, prov),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _confirmCancel(BuildContext ctx, HouseholdProvider prov) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.paddingOf(sheetCtx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Cancel this pickup?', style: HouseholdType.title),
          const SizedBox(height: 8),
          Text('You are limited to 3 cancellations per day.', style: HouseholdType.body.copyWith(color: HouseholdColors.gray)),
          const SizedBox(height: 24),
          HButton(
            label: 'Yes, cancel pickup',
            icon: 'security',
            onPressed: () async {
              Navigator.pop(sheetCtx);
              final id = _booking['id'] as String?;
              if (id == null) return;
              final nav = Navigator.of(ctx);
              await prov.cancelBooking(id, reason: 'Cancelled by household');
              if (mounted) nav.pushNamedAndRemoveUntil('/household', (_) => false);
            },
          ),
          const SizedBox(height: 10),
          HButton(label: 'Keep pickup', icon: 'pickup', secondary: true, onPressed: () => Navigator.pop(sheetCtx)),
        ]),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.status, required this.onBack});
  final String status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _PillBtn(icon: PhosphorIcons.caretLeft(), onTap: onBack),
      const SizedBox(width: 10),
      Expanded(
        child: HCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: 30,
          child: Row(children: [
            _StatusDot(status: status),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _statusLabel(status),
                style: HouseholdType.section.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  static String _statusLabel(String s) {
    const m = {
      'SEARCHING': 'Searching for collector...',
      'ASSIGNED':  'Collector assigned',
      'ACCEPTED':  'Collector accepted',
      'EN_ROUTE':  'Collector on the way',
      'ON_THE_WAY': 'Collector on the way',
      'ARRIVED':   'Collector arrived',
      'COLLECTING': 'Collection in progress',
      'COLLECTED': 'Waste collected',
      'COMPLETED': 'Pickup complete',
      'CANCELLED': 'Pickup cancelled',
    };
    return m[s] ?? s.replaceAll('_', ' ');
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  Color get _color {
    if (['COMPLETED', 'COLLECTED'].contains(status)) return const Color(0xFF22C55E);
    if (status == 'CANCELLED') return const Color(0xFFEF4444);
    if (['ARRIVED', 'COLLECTING'].contains(status)) return const Color(0xFF7C3AED);
    if (['EN_ROUTE', 'ON_THE_WAY', 'ACCEPTED', 'ASSIGNED'].contains(status)) return HouseholdColors.primary;
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(width: 9, height: 9, decoration: BoxDecoration(color: _color, shape: BoxShape.circle));
  }
}

// ─── Dark placeholder (while GPS resolves) ────────────────────────────────────

class _DarkPlaceholder extends StatelessWidget {
  const _DarkPlaceholder({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1821),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset(HouseholdAssets.searching, height: 120),
          const SizedBox(height: 16),
          Text('Acquiring location...', style: HouseholdType.section.copyWith(color: Colors.white)),
        ]),
      ),
    );
  }
}

// ─── Bottom Card ──────────────────────────────────────────────────────────────

class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.booking,
    required this.status,
    required this.collector,
    required this.onCall,
    required this.onCancel,
  });
  final Map<String, dynamic> booking;
  final String status;
  final Map<String, dynamic>? collector;
  final VoidCallback onCall;
  final VoidCallback onCancel;

  bool get _canCancel => ['SEARCHING', 'ASSIGNED', 'ACCEPTED'].contains(status);
  bool get _isDone    => ['COMPLETED', 'COLLECTED', 'CANCELLED'].contains(status);

  @override
  Widget build(BuildContext context) {
    final amount  = booking['totalAmount'];
    final address = booking['pickupAddress'] as String? ?? 'Pickup location';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 28, offset: Offset(0, -8))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status label
            _StatusLabel(status: status),
            const SizedBox(height: 16),

            // Collector row
            if (collector != null) ...[
              _CollectorRow(collector: collector!, onCall: onCall),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEEEAE2)),
              const SizedBox(height: 14),
            ] else if (status == 'SEARCHING') ...[
              _SearchAnim(),
              const SizedBox(height: 14),
            ],

            // Address + amount
            Row(children: [
              Icon(PhosphorIcons.mapPin(), size: 15, color: HouseholdColors.gray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(address, style: HouseholdType.caption.copyWith(color: HouseholdColors.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (amount != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(PhosphorIcons.money(), size: 15, color: HouseholdColors.gray),
                const SizedBox(width: 8),
                Text('GHS $amount', style: HouseholdType.number.copyWith(color: HouseholdColors.primary, fontSize: 16)),
              ]),
            ],
            const SizedBox(height: 16),

            // Actions
            if (_isDone)
              HButton(
                label: 'Back to home',
                icon: 'home',
                secondary: true,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/household', (_) => false),
              )
            else if (_canCancel)
              HButton(label: 'Cancel pickup', icon: 'security', secondary: true, onPressed: onCancel),
          ]),
        ),
      ]),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});
  final String status;

  Color get _color {
    if (['COMPLETED', 'COLLECTED'].contains(status)) return HouseholdColors.ecoGreen;
    if (status == 'CANCELLED') return HouseholdColors.danger;
    if (['ARRIVED', 'COLLECTING'].contains(status)) return const Color(0xFF7C3AED);
    if (['EN_ROUTE', 'ON_THE_WAY', 'ACCEPTED', 'ASSIGNED'].contains(status)) return HouseholdColors.primary;
    return HouseholdColors.warning;
  }

  String get _label {
    const m = {
      'SEARCHING':  'Searching for a collector...',
      'ASSIGNED':   'Collector assigned',
      'ACCEPTED':   'Collector accepted your request',
      'EN_ROUTE':   'Collector is on the way',
      'ON_THE_WAY': 'Collector is on the way',
      'ARRIVED':    'Collector has arrived',
      'COLLECTING': 'Collection in progress',
      'COLLECTED':  'Waste has been collected',
      'COMPLETED':  'Pickup complete',
      'CANCELLED':  'Pickup cancelled',
    };
    return m[status] ?? status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(_label, style: HouseholdType.section.copyWith(color: _color))),
    ]);
  }
}

class _CollectorRow extends StatelessWidget {
  const _CollectorRow({required this.collector, required this.onCall});
  final Map<String, dynamic> collector;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final name    = collector['fullName'] as String? ?? 'Your collector';
    final vehicle = collector['vehicleType'] as String?;
    final rating  = (collector['rating'] as num?)?.toDouble();
    final hasPhone = (collector['phone'] as String?)?.isNotEmpty == true;

    return Row(children: [
      _Avatar(name: name),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: HouseholdType.section),
          if (vehicle != null) Text(vehicle, style: HouseholdType.caption),
          if (rating != null)
            Row(children: [
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), color: HouseholdColors.warning, size: 13),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: HouseholdType.caption.copyWith(fontWeight: FontWeight.w700)),
            ]),
        ]),
      ),
      if (hasPhone)
        _PillBtn(icon: PhosphorIcons.phone(), onTap: onCall, color: HouseholdColors.ecoGreen),
    ]);
  }
}

class _SearchAnim extends StatefulWidget {
  @override
  State<_SearchAnim> createState() => _SearchAnimState();
}

class _SearchAnimState extends State<_SearchAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Row(children: [
        SvgPicture.asset(HouseholdAssets.searching, height: 44, width: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Searching for a collector', style: HouseholdType.section),
            Text('Finding the nearest available driver.', style: HouseholdType.caption),
          ]),
        ),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: HouseholdColors.primary.withAlpha(22),
        shape: BoxShape.circle,
        border: Border.all(color: HouseholdColors.primary.withAlpha(60)),
      ),
      child: Center(child: Text(initials, style: HouseholdType.section.copyWith(color: HouseholdColors.primary))),
    );
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? HouseholdColors.primary;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.withAlpha(20), border: Border.all(color: c.withAlpha(80))),
        child: Center(child: Icon(icon, color: c, size: 20)),
      ),
    );
  }
}
