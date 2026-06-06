import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/location_service.dart';
import '../providers/collector_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../screens/active_pickup_screen.dart';

class CollectorMapTab extends StatefulWidget {
  const CollectorMapTab({super.key, required this.pos});
  final LatLng pos;

  @override
  State<CollectorMapTab> createState() => _CollectorMapTabState();
}

class _CollectorMapTabState extends State<CollectorMapTab> {
  MapLibreMapController? _mapCtrl;

  @override
  void didUpdateWidget(CollectorMapTab old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(widget.pos));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    
    final active = prov.currentActivePickup;
    final requests = prov.pendingRequests;

    final currentLoad = user?.currentLoadKg ?? 0.0;
    final maxCapacity = user?.maxCapacityKg ?? 500.0;
    final loadPct = (currentLoad / maxCapacity).clamp(0.0, 1.0);

    return Stack(
      children: [
        // ── Map ───────────────────────────────────────────────────────────
        Positioned.fill(
          child: MapLibreMap(
            styleString: kMapStyleUrl,
            initialCameraPosition: CameraPosition(target: widget.pos, zoom: 14),
            onMapCreated: (c) => _mapCtrl = c,
            myLocationEnabled: false,
          ),
        ),

        // ── Header (Greeting + Stats PASS C/Pass 1) ──────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good day, ${user?.fullName?.split(' ').first ?? 'Collector'}', style: AppTextStyles.section),
                          const SizedBox(height: 4),
                          _CapacityBar(pct: loadPct, current: currentLoad, max: maxCapacity),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _OnlineToggle(
                      isOnline: prov.isOnline,
                      onToggle: () {
                        HapticFeedback.mediumImpact();
                        prov.toggleOnline();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TodayStatsRow(
                  balance: prov.walletAvailable, 
                  jobs: user?.totalPickups ?? 0,
                  rating: user?.rating ?? 5.0,
                ),
              ],
            ),
          ),
        ),

        // ── Bottom Cards (Active Job or Request Queue) ─────────────────────
        Positioned(
          bottom: 20, left: 16, right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active != null)
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: _ActiveJobCard(
                    booking: active,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ActivePickupScreen(booking: active)),
                    ),
                  ),
                )
              else if (prov.isOnline && requests.isNotEmpty)
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: _PendingRequestCard(
                    booking: requests.first,
                    collectorPos: widget.pos,
                    onAccept: () => prov.acceptRequest(requests.first['id']),
                    onDecline: () => prov.declineRequest(requests.first['id']),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({required this.balance, required this.jobs, required this.rating});
  final double balance;
  final int jobs;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _TodayItem(label: 'Balance', value: Fmt.currency(balance), isMono: true),
        _TodayItem(label: 'Total Jobs', value: '$jobs'),
        _TodayItem(label: 'Rating', value: '${rating.toStringAsFixed(1)} ★'),
      ],
    );
  }
}

class _TodayItem extends StatelessWidget {
  const _TodayItem({required this.label, required this.value, this.isMono = false});
  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: (isMono ? AppTextStyles.mono : AppTextStyles.bodyMedium).copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.pct, required this.current, required this.max});
  final double pct;
  final double current;
  final double max;

  @override
  Widget build(BuildContext context) {
    final color = pct > 0.8 ? AppColors.danger : (pct > 0.5 ? AppColors.warning : AppColors.primary);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('${current.toInt()}kg', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.isOnline, required this.onToggle});
  final bool isOnline;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: AppRadius.mdBR,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.mdBR,
        ),
        child: Row(
          children: [
            Icon(isOnline ? PhosphorIconsFill.power : PhosphorIconsRegular.power, 
                 color: isOnline ? Colors.white : AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(isOnline ? 'ONLINE' : 'OFFLINE', 
                 style: AppTextStyles.bodyMedium.copyWith(
                   color: isOnline ? Colors.white : AppColors.textMuted,
                   fontWeight: FontWeight.w800,
                   fontSize: 11,
                 )),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({required this.booking, required this.onTap});
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final address = booking['pickupAddress'] as String? ?? '—';
    final category = booking['wasteCategory'] as String? ?? 'HOUSEHOLD';
    
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBR,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdBR,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 30, offset: const Offset(0, 10))],
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.smBR),
                  child: const Icon(PhosphorIconsFill.truck, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Job', style: AppTextStyles.section),
                      Text(address, style: AppTextStyles.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(PhosphorIconsRegular.caretRight, color: AppColors.textMuted, size: 20),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: 'Type', value: Fmt.categoryLabel(category)),
                _StatItem(label: 'Weight', value: '${booking['estimatedWeightKg'] ?? 0} kg'),
                _StatItem(label: 'Payout', value: Fmt.currency(Fmt.toDouble(booking['totalAmount']) * 0.9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatefulWidget {
  const _PendingRequestCard({required this.booking, required this.collectorPos, required this.onAccept, required this.onDecline});
  final Map<String, dynamic> booking;
  final LatLng collectorPos;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _seconds = 30;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        widget.onDecline();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.booking['pickupAddress'] as String? ?? '—';
    final amount = Fmt.toDouble(widget.booking['totalAmount']) * 0.9;
    
    final distMeters = LocationService.distanceMeters(
      widget.collectorPos.latitude, widget.collectorPos.longitude,
      (widget.booking['pickupLat'] as num).toDouble(), (widget.booking['pickupLng'] as num).toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBR,
        boxShadow: [BoxShadow(color: AppColors.warning.withAlpha(40), blurRadius: 40, offset: const Offset(0, 15))],
        border: Border.all(color: AppColors.warning.withAlpha(150), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.warning.withAlpha(30), borderRadius: AppRadius.xsBR),
                child: Text('NEW REQUEST', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 9)),
              ),
              Text(Fmt.currency(amount), style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(child: Text(address, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Waste Type', value: Fmt.categoryLabel(widget.booking['wasteCategory'] as String? ?? '')),
              _StatItem(label: 'Est. weight', value: '${widget.booking['estimatedWeightKg'] ?? 0} kg'),
              _StatItem(label: 'Distance', value: LocationService.formatDistance(distMeters)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDecline,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.border), minimumSize: const Size(0, 56)),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onAccept,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Accept ($_seconds s)'),
                      const SizedBox(width: 8),
                      const Icon(PhosphorIconsFill.checkCircle, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
