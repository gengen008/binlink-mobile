import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/places_service.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/step_progress_bar.dart';
import '../../../shared/widgets/app_button.dart';
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
  final List<XFile> _wastePhotos = [];
  bool _isNow = true;
  DateTime? _scheduledDate;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  double _lat = 5.6037;
  double _lng = -0.1870;
  bool _locating = false;
  bool _uploadingPhotos = false;

  final Map<String, double> _kBinPrices = {'SMALL': 30, 'MEDIUM': 40, 'LARGE': 50};
  final double _kBagPrice = 6;

  double get _total => (_kBinPrices[_binSize] ?? 30) + (_extraBags * _kBagPrice);

  @override
  void initState() {
    super.initState();
    _isNow = widget.mode == 'immediate';
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        if (address != null) _addressCtrl.text = address;
        _locating = false;
      });
    } else {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _next() {
    if (_step < 5) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _confirm();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
      pickupLat: _lat,
      pickupLng: _lng,
      paymentMethod: 'CASH',
      wasteCategory: _category,
      scheduledDate: _isNow ? null : _scheduledDate,
      addressNotes: _notesCtrl.text.trim(),
    );

    if (booking != null && mounted) {
      if (_wastePhotos.isNotEmpty) {
        setState(() => _uploadingPhotos = true);
        try {
          final formData = FormData.fromMap({
            'photo': await MultipartFile.fromFile(_wastePhotos.first.path),
            'type': 'waste',
          });
          await ApiClient.instance.post('/api/bookings/${booking['id']}/photos', data: formData);
        } catch (_) {}
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();
    final canAdvance = _step == 0 ? _category != null : (_step == 4 ? _addressCtrl.text.isNotEmpty : true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppScaffoldBar(
        title: 'Book a Pickup',
        onBack: _back,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: StepProgressBar(totalSteps: 6, currentStep: _step),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepCategory(selected: _category, onSelect: (val) => setState(() => _category = val)),
                StepVolume(
                  binSize: _binSize,
                  extraBags: _extraBags,
                  onBinSize: (val) => setState(() => _binSize = val),
                  onExtraBags: (val) => setState(() => _extraBags = val),
                ),
                StepPhotos(
                  photos: _wastePhotos,
                  onAdd: () async {
                    final img = await ImagePicker().pickImage(source: ImageSource.camera);
                    if (img != null) setState(() => _wastePhotos.add(img));
                  },
                  onRemove: (i) => setState(() => _wastePhotos.removeAt(i)),
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
                  total: _total,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppButton(
              label: _step == 5 ? 'Confirm Booking' : 'Continue',
              onPressed: canAdvance ? _next : null,
              loading: prov.loading || _uploadingPhotos,
            ),
          ),
        ],
      ),
    );
  }
}
