import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/places_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/binlink_map.dart';
import '../providers/household_provider.dart';
import '../components/booking_steps.dart';
import 'payment_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, this.mode = 'immediate'});
  final String mode;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;

  // State
  String? _category;
  String _binSize = 'SMALL';
  int _extraBags = 0;
  bool _isNow = true;
  DateTime? _scheduledDate;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  LatLng _pickupPos = const LatLng(5.6037, -0.1870);
  bool _locating = false;
  GoogleMapController? _mapController;

  final Map<String, double> _kBinPrices = {'SMALL': 30, 'MEDIUM': 40, 'LARGE': 50};
  final double _kBagPrice = 6;
  final double _kServiceFee = 2.0;

  double get _total => (_kBinPrices[_binSize] ?? 30) + (_extraBags * _kBagPrice) + _kServiceFee;

  @override
  void initState() {
    super.initState();
    _isNow = widget.mode == 'immediate';
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Get initial quick fix
    final lastPos = await LocationService.getLastKnownPosition();
    if (lastPos != null) {
      _updatePickupPos(LatLng(lastPos.latitude, lastPos.longitude));
    }
    
    // Get fresh accurate fix
    _getLocation();
  }

  Future<void> _getLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        _updatePickupPos(latLng);
        
        final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);
        if (address != null && mounted) {
          _addressCtrl.text = address;
        }
      }
    } catch (_) {
      // Handle error quietly or show snackbar
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _updatePickupPos(LatLng pos) {
    if (!mounted) return;
    setState(() => _pickupPos = pos);
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutExpo);
    } else {
      _confirm();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutExpo);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _confirm() async {
    final prov = context.read<HouseholdProvider>();
    final booking = await prov.createBooking(
      binSize: _binSize,
      extraBags: _extraBags,
      pickupAddress: _addressCtrl.text.trim(),
      pickupLat: _pickupPos.latitude,
      pickupLng: _pickupPos.longitude,
      paymentMethod: 'CASH',
      wasteCategory: _category,
      scheduledDate: _isNow ? null : _scheduledDate,
      addressNotes: _notesCtrl.text.trim(),
    );

    if (booking != null && mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background Map ────────────────────────────────────────────────
          Positioned.fill(
            child: BinLinkMap(
              initialPosition: _pickupPos,
              myLocationEnabled: true,
              onMapCreated: (c) => _mapController = c,
              markers: {
                Marker(
                  markerId: const MarkerId('pickup_pin'),
                  position: _pickupPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
              },
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleNavBtn(icon: PhosphorIconsRegular.arrowLeft, onTap: _back),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.fullBR,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Text(
                    "Step ${_step + 1} of 5",
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 48), // Spacer
              ],
            ),
          ),

          // ── Bottom Sheet Content ──────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.sheetBR,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.fullBR)),
                  const SizedBox(height: 24),
                  
                  Flexible(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        StepCategory(selected: _category, onSelect: (val) {
                          setState(() => _category = val);
                          _next();
                        }),
                        StepVolume(
                          binSize: _binSize,
                          extraBags: _extraBags,
                          onBinSize: (val) => setState(() => _binSize = val),
                          onExtraBags: (val) => setState(() => _extraBags = val),
                        ),
                        StepSchedule(
                          isNow: _isNow,
                          scheduledDate: _scheduledDate,
                          onNowChanged: (val) => setState(() => _isNow = val),
                          onDateChanged: (val) => setState(() => _scheduledDate = val),
                        ),
                        StepAddress(
                          addressCtrl: _addressCtrl,
                          notesCtrl: _notesCtrl,
                          onLocate: _getLocation,
                          locating: _locating,
                        ),
                        StepReview(
                          category: _category ?? '',
                          binSize: _binSize,
                          extraBags: _extraBags,
                          address: _addressCtrl.text,
                          isNow: _isNow,
                          total: _total - _kServiceFee,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: AppButton(
                      label: _step == 4 ? "Confirm Booking" : "Next",
                      onPressed: _category != null ? _next : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleNavBtn extends StatelessWidget {
  const _CircleNavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
