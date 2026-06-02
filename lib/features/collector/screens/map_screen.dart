import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/app_button.dart';
import 'active_pickup_screen.dart';
import 'earnings_screen.dart';

class CollectorMapScreen extends StatefulWidget {
  const CollectorMapScreen({super.key});

  @override
  State<CollectorMapScreen> createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  LatLng _pos = const LatLng(5.6037, -0.1870);
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) setState(() => _pos = LatLng(pos.latitude, pos.longitude));
    if (mounted) await context.read<CollectorProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _MapTab(pos: _pos),
          const EarningsScreen(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.deepOcean,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _NavItem(icon: PhosphorIconsRegular.mapTrifold, label: 'Map',      index: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
              _NavItem(icon: PhosphorIconsRegular.coins,      label: 'Earnings', index: 1, current: _tab, onTap: (i) => setState(() => _tab = i)),
              _NavItem(icon: PhosphorIconsRegular.user,       label: 'Profile',  index: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapTab extends StatefulWidget {
  const _MapTab({required this.pos});
  final LatLng pos;

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final Completer<GoogleMapController> _mapCtrl = Completer();

  void _onMapCreated(GoogleMapController ctrl) {
    if (!_mapCtrl.isCompleted) _mapCtrl.complete(ctrl);
  }

  @override
  void didUpdateWidget(_MapTab old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      _mapCtrl.future.then((ctrl) {
        ctrl.animateCamera(CameraUpdate.newLatLng(widget.pos));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final auth = context.watch<AuthProvider>();
    final active = prov.currentActivePickup;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: widget.pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          prov.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(title: prov.isOnline ? 'Online' : 'Offline'),
      ),
    };

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Stack(
        children: [
          // Google Map (full screen)
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.pos,
              zoom: 14,
            ),
            style: kDarkMapStyle,
            markers: markers,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // UI overlay
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.deepOcean,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.user, color: AppColors.skyBlue, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.user?.fullName ?? 'Collector',
                                  style: AppTextStyles.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Online toggle
                      GestureDetector(
                        onTap: () => prov.toggleOnline(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: prov.isOnline
                                ? AppColors.success.withAlpha(25)
                                : AppColors.muted.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: prov.isOnline ? AppColors.success : AppColors.muted,
                            ),
                          ),
                          child: Text(
                            prov.isOnline ? 'Online' : 'Offline',
                            style: AppTextStyles.label.copyWith(
                              color: prov.isOnline ? AppColors.success : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active pickup banner
                if (active != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ActivePickupScreen(booking: active))),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsFill.truck, color: AppColors.white, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Active Pickup', style: AppTextStyles.h4.copyWith(color: AppColors.white)),
                                  Text(
                                    active['pickupAddress'] as String? ?? '',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.iceBlue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Pending requests
                if (prov.pendingRequests.isNotEmpty && prov.isOnline)
                  _PendingRequestsList(requests: prov.pendingRequests),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestsList extends StatelessWidget {
  const _PendingRequestsList({required this.requests});
  final List<Map<String, dynamic>> requests;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        padEnds: false,
        controller: PageController(viewportFraction: 0.9),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final req = requests[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _RequestCard(booking: req),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final prov = context.read<CollectorProvider>();
    final binSize = booking['binSize'] as String? ?? '';
    final address = booking['pickupAddress'] as String? ?? '';
    final amount  = (booking['totalAmount'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepOcean,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(Fmt.binSizeLabel(binSize), style: AppTextStyles.label.copyWith(color: AppColors.steelBlue)),
              ),
              const Spacer(),
              Text(Fmt.currency(amount), style: AppTextStyles.mono.copyWith(color: AppColors.iceBlue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin, color: AppColors.skyBlue, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Decline',
                  variant: AppButtonVariant.danger,
                  height: 40,
                  onPressed: () => prov.declineRequest(booking['id'] as String),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Accept',
                  height: 40,
                  onPressed: () async {
                    final ok = await prov.acceptRequest(booking['id'] as String);
                    if (ok && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivePickupScreen(booking: prov.currentActivePickup!),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.steelBlue.withAlpha(60), blurRadius: 20)],
                ),
                child: Center(
                  child: Text(
                    Fmt.initials(user?.fullName),
                    style: AppTextStyles.h2.copyWith(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user?.fullName ?? 'Collector', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(user?.phone ?? '', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),

              if (user?.vehicleType != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.truck, color: AppColors.skyBlue, size: 16),
                      const SizedBox(width: 6),
                      Text('${user?.vehicleType} • ${user?.vehiclePlate}', style: AppTextStyles.label),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Sign Out', style: AppTextStyles.h3),
                      content: Text(
                        'You will be signed out.',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Sign Out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(PhosphorIconsRegular.signOut, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Text('Sign Out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text('BinLink Collector v2.0.0', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
  });
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? AppColors.steelBlue : AppColors.muted, size: 24),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.steelBlue : AppColors.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
