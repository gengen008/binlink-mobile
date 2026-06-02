import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/booking_card.dart';
import 'book_screen.dart';
import 'tracking_screen.dart';

class HouseholdHomeScreen extends StatefulWidget {
  const HouseholdHomeScreen({super.key});

  @override
  State<HouseholdHomeScreen> createState() => _HouseholdHomeScreenState();
}

class _HouseholdHomeScreenState extends State<HouseholdHomeScreen> {
  LatLng _myPos = const LatLng(5.6037, -0.1870); // Accra default
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
    final prov = context.read<HouseholdProvider>();
    await prov.loadBookings();
    if (!mounted) return;
    await prov.loadOnlineCollectors();
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

// ── Home tab ─────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.myPos});
  final LatLng myPos;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final Completer<GoogleMapController> _mapCtrl = Completer();

  void _onMapCreated(GoogleMapController ctrl) {
    if (!_mapCtrl.isCompleted) _mapCtrl.complete(ctrl);
  }

  @override
  void didUpdateWidget(_HomeTab old) {
    super.didUpdateWidget(old);
    if (old.myPos != widget.myPos) {
      _mapCtrl.future.then((ctrl) {
        ctrl.animateCamera(CameraUpdate.newLatLng(widget.myPos));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final auth = context.watch<AuthProvider>();
    final active = prov.activeBooking;

    // Build marker set
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: widget.myPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'My Location'),
      ),
      ...prov.onlineCollectors.map((c) {
        final lat = (c['lastLat'] as num?)?.toDouble();
        final lng = (c['lastLng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        return Marker(
          markerId: MarkerId('collector_${c['id']}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: c['fullName'] as String? ?? 'Collector'),
        );
      }).whereType<Marker>(),
    };

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_greeting()},',
                          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          auth.user?.fullName ?? 'Household',
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(PhosphorIconsRegular.bell, color: AppColors.skyBlue, size: 22),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Active booking banner or Book Now card
          if (active != null)
            _ActiveBookingBanner(booking: active)
          else
            _BookNowCard(),

          const SizedBox(height: 16),

          // Google Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: widget.myPos,
                    zoom: 14,
                  ),
                  style: kDarkMapStyle,
                  markers: markers,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _ActiveBookingBanner extends StatelessWidget {
  const _ActiveBookingBanner({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'PENDING';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: booking['id'] as String)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsFill.trashSimple, color: AppColors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Fmt.statusLabel(status),
                        style: AppTextStyles.h4.copyWith(color: AppColors.white)),
                    Text('Tap to track your pickup',
                        style: AppTextStyles.caption.copyWith(color: AppColors.iceBlue)),
                  ],
                ),
              ),
              const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookNowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(PhosphorIconsFill.trashSimple, color: AppColors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule Pickup', style: AppTextStyles.h4),
                    SizedBox(height: 2),
                    Text('Book a collector now or later', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.arrowRight, color: AppColors.steelBlue, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History tab ────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final bookings = prov.completedBookings;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Text('History', style: AppTextStyles.h2),
                  const Spacer(),
                  Text('${bookings.length} pickups', style: AppTextStyles.caption),
                ],
              ),
            ),
            Expanded(
              child: bookings.isEmpty
                  ? _EmptyState(
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      title: 'No history yet',
                      subtitle: 'Your completed pickups will appear here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: bookings.length,
                      itemBuilder: (_, i) => BookingCard(
                        booking: bookings[i],
                        showCollector: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile tab ────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Future<void> _editPhone(BuildContext context, AuthProvider auth) async {
    final ctrl = TextEditingController(text: auth.user?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            auth.user?.phone == null ? 'Add Phone Number' : 'Edit Phone Number',
            style: AppTextStyles.h3,
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: '+233 XX XXX XXXX',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
                prefixIcon: const Icon(PhosphorIconsRegular.phone, color: AppColors.muted, size: 20),
                filled: true,
                fillColor: AppColors.deepOcean,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number required';
                final cleaned = v.replaceAll(RegExp(r'[\s\-()]'), '');
                if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleaned)) return 'Enter a valid phone number';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
            ),
            TextButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() => saving = true);
                try {
                  final res = await ApiClient.put('/api/profile', {'phone': ctrl.text.trim()});
                  final updated = UserModel.fromJson(res.data['data']);
                  auth.updateUser(updated);
                } catch (_) {} finally {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: Text('Save', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.steelBlue)),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

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
              Text(user?.fullName ?? 'Household', style: AppTextStyles.h3),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(user!.email!, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 24),

              // Phone row
              GestureDetector(
                onTap: () => _editPhone(context, auth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.phone, color: AppColors.skyBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone Number', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(
                              user?.phone ?? 'Tap to add',
                              style: AppTextStyles.body.copyWith(
                                color: user?.phone != null ? AppColors.white : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.muted, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign out
              GestureDetector(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Sign Out', style: AppTextStyles.h3),
                      content: Text(
                        'You will be signed out of your account.',
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
              Text('BinLink Eco v2.0.0', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepOcean,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(icon: PhosphorIconsRegular.house,                 label: 'Home',    index: 0, current: current, onTap: onTap),
            _NavItem(icon: PhosphorIconsRegular.clockCounterClockwise, label: 'History', index: 1, current: current, onTap: onTap),
            _NavItem(icon: PhosphorIconsRegular.user,                  label: 'Profile', index: 2, current: current, onTap: onTap),
          ],
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
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.steelBlue : AppColors.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.muted, size: 48),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
