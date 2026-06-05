import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../providers/household_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/places_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/step_progress_bar.dart';
import '../../../shared/widgets/date_picker_row.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/location_search_sheet.dart';
import 'payment_screen.dart';
import '../../../core/theme/app_radius.dart';

// ── Pricing constants ─────────────────────────────────────────────────────────

const Map<String, double> _kBinPrices  = {'SMALL': 30, 'MEDIUM': 40, 'LARGE': 50};
const double _kBagPrice   = 6;

// ── Step labels ───────────────────────────────────────────────────────────────

const List<String> _kStepLabels = [
  'Category', 'Volume', 'Photos', 'Schedule', 'Address', 'Review',
];

// ── Waste categories ──────────────────────────────────────────────────────────

class _WasteCategory {
  const _WasteCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.desc,
    this.earnsPoints = false,
  });
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String desc;
  final bool earnsPoints;
}

const List<_WasteCategory> _kCategories = [
  _WasteCategory(
    key: 'HOUSEHOLD',
    label: 'Household Waste',
    icon: PhosphorIconsFill.trashSimple,
    color: AppColors.steelBlue,
    desc: 'General home rubbish',
  ),
  _WasteCategory(
    key: 'PLASTIC',
    label: 'Plastic & Recyclables',
    icon: PhosphorIconsFill.recycle,
    color: AppColors.success,
    desc: 'Bottles, bags, containers',
    earnsPoints: true,
  ),
  _WasteCategory(
    key: 'GLASS',
    label: 'Glass',
    icon: PhosphorIconsFill.wine,
    color: AppColors.skyBlue,
    desc: 'Bottles, jars, windows',
    earnsPoints: true,
  ),
  _WasteCategory(
    key: 'METAL',
    label: 'Metal & Scrap',
    icon: PhosphorIconsFill.wrench,
    color: AppColors.warning,
    desc: 'Cans, pipes, appliances',
    earnsPoints: true,
  ),
  _WasteCategory(
    key: 'ORGANIC',
    label: 'Organic & Food',
    icon: PhosphorIconsFill.leaf,
    color: Color(0xFF34D399),
    desc: 'Food scraps, garden waste',
    earnsPoints: true,
  ),
  _WasteCategory(
    key: 'CONSTRUCTION',
    label: 'Construction Debris',
    icon: PhosphorIconsFill.hammer,
    color: Color(0xFFF97316),
    desc: 'Rubble, tiles, wood',
  ),
  _WasteCategory(
    key: 'EWASTE',
    label: 'E-Waste',
    icon: PhosphorIconsFill.laptop,
    color: Color(0xFFA78BFA),
    desc: 'Electronics, batteries',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// BookScreen
// ─────────────────────────────────────────────────────────────────────────────

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, this.mode = 'immediate'});

  /// 'immediate' → default to "Now" tab | 'scheduled' → default to schedule tab
  final String mode;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _anim;
  late Animation<double> _fade;

  // Step state
  int _step = 0;

  // Step 1 — Category
  String? _category;

  // Step 2 — Volume
  String _binSize   = 'SMALL';
  int    _extraBags  = 0;
  int    _estWeightKg = 100;

  // Step 3 — Waste photos (optional)
  final _picker = ImagePicker();
  final List<XFile> _wastePhotos = [];
  bool _uploadingPhotos = false;

  // Step 4 — Schedule
  bool      _isNow         = true;
  DateTime? _scheduledDate;
  String    _timePref       = 'MORNING';
  String    _frequency      = 'ONE_TIME';

  // Step 5 — Address
  final _addressCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();
  double _lat         = 5.6037;
  double _lng         = -0.1870;
  bool   _locating    = false;

  // Step 6 — Payment
  final String _payMethod = 'CASH';

  double get _base      => _kBinPrices[_binSize] ?? 30;
  double get _extrasAmt => _extraBags * _kBagPrice;
  double get _total     => _base + _extrasAmt;

  @override
  void initState() {
    super.initState();
    _isNow = widget.mode == 'immediate';
    _anim  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _getLocation();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _anim.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _locating = false;
        });
        if (address != null && _addressCtrl.text.isEmpty) {
          _addressCtrl.text = address;
        }
      }
    } else if (mounted) {
      setState(() => _locating = false);
    }
  }

  void _onAddressSelected(String address, double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
    });
    _addressCtrl.text = address;
  }

  void _toStep(int s) {
    if (s < 0 || s >= 6) return;
    setState(() => _step = s);
    _anim.forward(from: 0);
    _pageCtrl.animateToPage(s,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  bool _canAdvance() {
    switch (_step) {
      case 0: return _category != null;
      case 1: return true; // Volume
      case 2: return true; // Photos — optional
      case 3: return _isNow || _scheduledDate != null;
      case 4: return _addressCtrl.text.trim().isNotEmpty;
      case 5: return true; // Review
    }
    return true;
  }

  Future<void> _confirm() async {
    if (_addressCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();

    final prov = context.read<HouseholdProvider>();
    final booking = await prov.createBooking(
      binSize: _binSize,
      extraBags: _extraBags,
      pickupAddress: _addressCtrl.text.trim(),
      pickupLat: _lat,
      pickupLng: _lng,
      paymentMethod: _payMethod,
      wasteCategory: _category,
      timePreference: _isNow ? null : _timePref,
      estimatedWeightKg: _estWeightKg.toDouble(),
      scheduledDate: _isNow ? null : _scheduledDate,
      frequency: _isNow ? null : (_frequency == 'ONE_TIME' ? null : _frequency),
      addressNotes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    if (booking != null) {
      // Upload waste photo if user took one
      if (_wastePhotos.isNotEmpty) {
        setState(() => _uploadingPhotos = true);
        try {
          final file = _wastePhotos.first;
          final formData = FormData.fromMap({
            'photo': await MultipartFile.fromFile(file.path, filename: 'waste.jpg'),
            'type': 'waste',
          });
          await ApiClient.instance.post(
            '/api/bookings/${booking['id']}/photos',
            data: formData,
          );
        } catch (_) {}
        if (mounted) setState(() => _uploadingPhotos = false);
      }
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Failed to create booking'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HouseholdProvider>();

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      // ── AppBar (Rydr: dark solid bar, rounded-square back button, left-aligned title) ──
      appBar: AppScaffoldBar(
        centerTitle: false,
        onBack: () {
          if (_step > 0) {
            _toStep(_step - 1);
          } else {
            Navigator.pop(context);
          }
        },
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Book a Pickup', style: AppTextStyles.appBarTitle),
            Text(
              'Step ${_step + 1} of 6 — ${_kStepLabels[_step]}',
              style: AppTextStyles.appBarSub,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Step progress bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StepProgressBar(
                totalSteps: 6,
                currentStep: _step,
              ),
            ),

            const SizedBox(height: 20),

            // ── Step pages ─────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1Category(
                    selected: _category,
                    onSelect: (k) => setState(() => _category = k),
                    fade: _fade,
                  ),
                  _Step2Volume(
                    binSize: _binSize,
                    extraBags: _extraBags,
                    estWeight: _estWeightKg,
                    onBinSize: (s) => setState(() => _binSize = s),
                    onExtraBags: (v) => setState(() => _extraBags = v),
                    onWeight: (v) => setState(() => _estWeightKg = v),
                    fade: _fade,
                  ),
                  _Step3Photos(
                    photos: _wastePhotos,
                    uploading: _uploadingPhotos,
                    onPickImage: () async {
                      final img = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 75,
                      );
                      if (img != null) setState(() => _wastePhotos.add(img));
                    },
                    onPickGallery: () async {
                      final imgs = await _picker.pickMultiImage(imageQuality: 75);
                      if (imgs.isNotEmpty) setState(() => _wastePhotos.addAll(imgs));
                    },
                    onRemove: (i) => setState(() => _wastePhotos.removeAt(i)),
                    fade: _fade,
                  ),
                  _Step3Schedule(
                    isNow: _isNow,
                    selectedDate: _scheduledDate,
                    timePref: _timePref,
                    frequency: _frequency,
                    onNow: (v) => setState(() => _isNow = v),
                    onDate: (d) => setState(() => _scheduledDate = d),
                    onTimePref: (t) => setState(() => _timePref = t),
                    onFrequency: (f) => setState(() => _frequency = f),
                    fade: _fade,
                  ),
                  _Step4Address(
                    addressCtrl: _addressCtrl,
                    notesCtrl: _notesCtrl,
                    lat: _lat,
                    lng: _lng,
                    locating: _locating,
                    onLocate: _getLocation,
                    onAddressSelected: _onAddressSelected,
                    fade: _fade,
                  ),
                  _Step5Review(
                    category: _category,
                    binSize: _binSize,
                    extraBags: _extraBags,
                    address: _addressCtrl.text,
                    isNow: _isNow,
                    scheduledDate: _scheduledDate,
                    timePref: _timePref,
                    frequency: _frequency,
                    base: _base,
                    extrasAmt: _extrasAmt,
                    total: _total,
                    payMethod: _payMethod,
                    fade: _fade,
                  ),
                ],
              ),
            ),

            // ── Next / Confirm button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppButton(
                label: _step == 5 ? 'Confirm & Pay ${Fmt.currency(_total)}' : 'Continue',
                loading: prov.loading || _uploadingPhotos,
                onPressed: _canAdvance()
                    ? () => _step == 5 ? _confirm() : _toStep(_step + 1)
                    : null,
                icon: _step == 5
                    ? const Icon(PhosphorIconsRegular.checkCircle,
                        color: AppColors.white, size: 20)
                    : const Icon(PhosphorIconsRegular.arrowRight,
                        color: AppColors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Waste Category
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Category extends StatelessWidget {
  const _Step1Category({
    required this.selected,
    required this.onSelect,
    required this.fade,
  });
  final String? selected;
  final ValueChanged<String> onSelect;
  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What are you disposing?',
                style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Select the primary waste type',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: _kCategories.map((cat) {
                final sel = selected == cat.key;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(cat.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withAlpha(30)
                          : AppColors.card,
                      borderRadius: AppRadius.xlBR,
                      border: Border.all(
                        color: sel ? cat.color : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: cat.color.withAlpha(50),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: cat.color.withAlpha(sel ? 40 : 20),
                                borderRadius: AppRadius.mdBR,
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 18),
                            ),
                            const Spacer(),
                            if (cat.earnsPoints)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(25),
                                  borderRadius: AppRadius.smBR,
                                ),
                                child: Text(
                                  '+10 pts',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(cat.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: sel ? cat.color : AppColors.textPrimary,
                              fontSize: 13,
                            )),
                        const SizedBox(height: 2),
                        Text(cat.desc,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Volume & Extras
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Volume extends StatelessWidget {
  const _Step2Volume({
    required this.binSize,
    required this.extraBags,
    required this.estWeight,
    required this.onBinSize,
    required this.onExtraBags,
    required this.onWeight,
    required this.fade,
  });
  final String binSize;
  final int extraBags;
  final int estWeight;
  final ValueChanged<String> onBinSize;
  final ValueChanged<int> onExtraBags;
  final ValueChanged<int> onWeight;
  final Animation<double> fade;

  static const _sizes = [
    {'key': 'SMALL',  'label': 'Small',  'volume': '≤120L', 'desc': 'For 1-2 bin bags', 'price': 30.0},
    {'key': 'MEDIUM', 'label': 'Medium', 'volume': '180L',  'desc': 'For 3-4 bin bags', 'price': 40.0},
    {'key': 'LARGE',  'label': 'Large',  'volume': '240L',  'desc': 'For 5+ bin bags',  'price': 50.0},
  ];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How much waste?', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Select bin size and extras',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                )),

            const SizedBox(height: 20),
            const Text('Bin Size', style: AppTextStyles.label),
            const SizedBox(height: 12),

            // Bin size cards
            ..._sizes.map((s) {
              final sel = binSize == s['key'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onBinSize(s['key'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.primaryGradient : null,
                    color: sel ? null : AppColors.card,
                    borderRadius: AppRadius.xlBR,
                    border: Border.all(
                      color: sel ? AppColors.steelBlue : AppColors.border,
                      width: sel ? 1.5 : 1,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: AppColors.steelBlue.withAlpha(60),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.white.withAlpha(20)
                              : AppColors.steelBlue.withAlpha(20),
                          borderRadius: AppRadius.mdBR,
                        ),
                        child: Icon(PhosphorIconsFill.trashSimple,
                            color: sel
                                ? AppColors.white
                                : AppColors.steelBlue,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(s['label'] as String,
                                    style: AppTextStyles.h4.copyWith(
                                      color: sel
                                          ? AppColors.white
                                          : AppColors.textPrimary,
                                    )),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.white.withAlpha(30)
                                        : AppColors.border,
                                    borderRadius: AppRadius.xsBR,
                                  ),
                                  child: Text(s['volume'] as String,
                                      style: AppTextStyles.caption.copyWith(
                                        color: sel
                                            ? AppColors.iceBlue
                                            : AppColors.muted,
                                        fontSize: 10,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(s['desc'] as String,
                                style: AppTextStyles.caption.copyWith(
                                  color: sel
                                      ? AppColors.iceBlue
                                      : AppColors.muted,
                                )),
                          ],
                        ),
                      ),
                      Text(Fmt.currency(s['price'] as double),
                          style: AppTextStyles.mono.copyWith(
                            color: sel
                                ? AppColors.white
                                : AppColors.iceBlue,
                          )),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Extra bags
            Row(
              children: [
                const Text('Extra Bags', style: AppTextStyles.label),
                const Spacer(),
                Text('GHC ${_kBagPrice.toStringAsFixed(0)} each',
                    style: AppTextStyles.monoSm),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.xlBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _CountBtn(
                    icon: PhosphorIconsRegular.minus,
                    onTap: extraBags > 0
                        ? () => onExtraBags(extraBags - 1)
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('$extraBags',
                            style: AppTextStyles.monoLg,
                            textAlign: TextAlign.center),
                        if (extraBags > 0)
                          Text(
                            '+ ${Fmt.currency(extraBags * _kBagPrice)}',
                            style: AppTextStyles.monoSm.copyWith(
                              color: AppColors.iceBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  _CountBtn(
                    icon: PhosphorIconsRegular.plus,
                    onTap: () => onExtraBags(extraBags + 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Estimated weight slider
            Row(
              children: [
                const Text('Estimated Weight', style: AppTextStyles.label),
                const Spacer(),
                Text('~${estWeight}kg',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.iceBlue,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.steelBlue,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.steelBlue,
                overlayColor: AppColors.steelBlue.withAlpha(30),
                trackHeight: 4,
              ),
              child: Slider(
                value: estWeight.toDouble(),
                min: 0,
                max: 500,
                divisions: 10,
                onChanged: (v) => onWeight(v.toInt()),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0kg', style: AppTextStyles.caption),
                  Text('500kg', style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Waste Photos (optional)
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Photos extends StatelessWidget {
  const _Step3Photos({
    required this.photos,
    required this.uploading,
    required this.onPickImage,
    required this.onPickGallery,
    required this.onRemove,
    required this.fade,
  });
  final List<XFile> photos;
  final bool uploading;
  final VoidCallback onPickImage;
  final VoidCallback onPickGallery;
  final ValueChanged<int> onRemove;
  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Waste Photos', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Optional — helps collector prepare for pickup',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Photo grid
            if (photos.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (_, i) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.mdBR,
                      child: Image.file(
                        File(photos[i].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(i),
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withAlpha(220),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(PhosphorIconsRegular.x,
                              color: AppColors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Camera / gallery buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.xlBR,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.steelBlue.withAlpha(20),
                              borderRadius: AppRadius.mdBR,
                            ),
                            child: const Icon(PhosphorIconsFill.camera,
                                color: AppColors.steelBlue, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text('Camera', style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onPickGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.xlBR,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.skyBlue.withAlpha(20),
                              borderRadius: AppRadius.mdBR,
                            ),
                            child: const Icon(PhosphorIconsFill.images,
                                color: AppColors.skyBlue, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text('Gallery', style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Skip hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.info,
                      color: AppColors.muted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Photos are optional. Tap Continue to skip this step.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted, height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Date & Time
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Schedule extends StatelessWidget {
  const _Step3Schedule({
    required this.isNow,
    required this.selectedDate,
    required this.timePref,
    required this.frequency,
    required this.onNow,
    required this.onDate,
    required this.onTimePref,
    required this.onFrequency,
    required this.fade,
  });
  final bool isNow;
  final DateTime? selectedDate;
  final String timePref;
  final String frequency;
  final ValueChanged<bool> onNow;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onTimePref;
  final ValueChanged<String> onFrequency;
  final Animation<double> fade;

  static const _frequencies = [
    ('ONE_TIME',  'One-time',  PhosphorIconsRegular.calendarBlank),
    ('WEEKLY',    'Weekly',    PhosphorIconsRegular.repeat),
    ('BIWEEKLY',  'Biweekly',  PhosphorIconsRegular.arrowsCounterClockwise),
    ('MONTHLY',   'Monthly',   PhosphorIconsRegular.calendarCheck),
  ];

  static const _timePrefs = [
    {'key': 'MORNING',   'label': 'Morning',   'range': '7am – 11am',  'icon': PhosphorIconsFill.sun},
    {'key': 'AFTERNOON', 'label': 'Afternoon', 'range': '12pm – 4pm',  'icon': PhosphorIconsFill.cloud},
    {'key': 'EVENING',   'label': 'Evening',   'range': '4pm – 7pm',   'icon': PhosphorIconsFill.moon},
  ];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('When should we come?', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Choose immediate or scheduled pickup',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                )),

            const SizedBox(height: 20),

            // Mode toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.xlBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _ToggleTab(
                    label: 'Now',
                    icon: PhosphorIconsRegular.lightning,
                    selected: isNow,
                    onTap: () => onNow(true),
                  ),
                  _ToggleTab(
                    label: 'Schedule',
                    icon: PhosphorIconsRegular.calendarBlank,
                    selected: !isNow,
                    onTap: () => onNow(false),
                  ),
                ],
              ),
            ),

            if (isNow) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withAlpha(15),
                  borderRadius: AppRadius.xlBR,
                  border: Border.all(
                      color: AppColors.steelBlue.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.steelBlue.withAlpha(25),
                        borderRadius: AppRadius.lgBR,
                      ),
                      child: const Icon(PhosphorIconsFill.lightning,
                          color: AppColors.steelBlue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Immediate Pickup',
                              style: AppTextStyles.h4),
                          const SizedBox(height: 4),
                          Text(
                            'A collector will be assigned and arrive within ~15 minutes based on availability.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              const Text('Select Date', style: AppTextStyles.label),
              const SizedBox(height: 12),
              DatePickerRow(
                selectedDate: selectedDate,
                onDateSelected: onDate,
              ),

              const SizedBox(height: 24),
              // Recurring frequency
              const Text('Pickup Frequency', style: AppTextStyles.label),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _frequencies.map((f) {
                  final sel = frequency == f.$1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onFrequency(f.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.primaryGradient : null,
                        color: sel ? null : AppColors.card,
                        borderRadius: AppRadius.mdBR,
                        border: Border.all(
                          color: sel ? AppColors.steelBlue : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f.$3,
                              color: sel ? AppColors.white : AppColors.muted,
                              size: 15),
                          const SizedBox(width: 6),
                          Text(f.$2,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: sel ? AppColors.white : AppColors.textPrimary,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Text('Preferred Time', style: AppTextStyles.label),
              const SizedBox(height: 12),
              Row(
                children: _timePrefs.map((t) {
                  final sel = timePref == t['key'];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: t['key'] == 'EVENING' ? 0 : 10,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTimePref(t['key'] as String);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.primaryGradient : null,
                            color: sel ? null : AppColors.card,
                            borderRadius: AppRadius.lgBR,
                            border: Border.all(
                              color: sel
                                  ? AppColors.steelBlue
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t['icon'] as IconData,
                                color: sel ? AppColors.white : AppColors.muted,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(t['label'] as String,
                                  style: AppTextStyles.caption.copyWith(
                                    color: sel
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  )),
                              const SizedBox(height: 2),
                              Text(t['range'] as String,
                                  style: AppTextStyles.caption.copyWith(
                                    color: sel
                                        ? AppColors.iceBlue
                                        : AppColors.muted,
                                    fontSize: 9,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.info,
                      color: AppColors.muted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pickups are assigned to the nearest available collector. Arrival times are estimates.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Pickup Address
// ─────────────────────────────────────────────────────────────────────────────

class _Step4Address extends StatefulWidget {
  const _Step4Address({
    required this.addressCtrl,
    required this.notesCtrl,
    required this.lat,
    required this.lng,
    required this.locating,
    required this.onLocate,
    required this.onAddressSelected,
    required this.fade,
  });
  final TextEditingController addressCtrl;
  final TextEditingController notesCtrl;
  final double lat;
  final double lng;
  final bool locating;
  final VoidCallback onLocate;
  final void Function(String address, double lat, double lng) onAddressSelected;
  final Animation<double> fade;

  @override
  State<_Step4Address> createState() => _Step4AddressState();
}

class _Step4AddressState extends State<_Step4Address> {
  @override
  void initState() {
    super.initState();
    widget.addressCtrl.addListener(_onAddressChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().loadSavedAddresses();
    });
  }

  @override
  void dispose() {
    widget.addressCtrl.removeListener(_onAddressChanged);
    super.dispose();
  }

  void _onAddressChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // target used by _StaticMapPin — kept as named val for readability
    final targetLat = widget.lat;
    final targetLng = widget.lng;

    return FadeTransition(
      opacity: widget.fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Where is the pickup?', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Confirm your location or enter address',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                )),

            const SizedBox(height: 20),

            // ── Saved address quick-chips ────────────────────────────
            Consumer<HouseholdProvider>(
              builder: (_, prov, __) {
                final saved = prov.savedAddresses;
                if (saved.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saved Addresses', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: saved.map((a) {
                          final label = a['label'] as String? ?? 'Address';
                          final addr  = a['address'] as String? ?? '';
                          final notes = a['gateNotes'] as String?;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                widget.addressCtrl.text = addr;
                                if (notes != null && notes.isNotEmpty) {
                                  widget.notesCtrl.text = notes;
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.steelBlue.withAlpha(20),
                                  borderRadius: AppRadius.mdBR,
                                  border: Border.all(
                                      color: AppColors.steelBlue.withAlpha(60)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      label.toUpperCase() == 'HOME'
                                          ? PhosphorIconsFill.house
                                          : label.toUpperCase() == 'OFFICE'
                                              ? PhosphorIconsFill.buildings
                                              : PhosphorIconsFill.mapPin,
                                      color: AppColors.steelBlue,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(label,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.steelBlue,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Map preview — tap to search
            GestureDetector(
              onTap: () async {
                final result = await showLocationSearch(
                  context,
                  lat: widget.lat,
                  lng: widget.lng,
                );
                if (result != null) {
                  widget.onAddressSelected(result.address, result.lat, result.lng);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      _StaticMapPin(lat: targetLat, lng: targetLng),
                      // Tap overlay hint
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.deepOcean.withAlpha(220),
                            borderRadius: BorderRadius.circular(AppRadius.sheet),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsRegular.magnifyingGlass,
                                  color: AppColors.steelBlue, size: 12),
                              const SizedBox(width: 5),
                              Text('Tap to search',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.steelBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search / Use current location row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showLocationSearch(
                        context,
                        lat: widget.lat,
                        lng: widget.lng,
                      );
                      if (result != null) {
                        widget.onAddressSelected(result.address, result.lat, result.lng);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppRadius.mdBR,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.steelBlue.withAlpha(50),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsRegular.magnifyingGlass,
                              color: AppColors.white, size: 15),
                          SizedBox(width: 7),
                          Text('Search Address',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: widget.onLocate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.steelBlue.withAlpha(20),
                      borderRadius: AppRadius.mdBR,
                      border: Border.all(
                          color: AppColors.steelBlue.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.locating
                            ? const SizedBox(
                                width: 15, height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.steelBlue))
                            : const Icon(PhosphorIconsFill.crosshair,
                                color: AppColors.steelBlue, size: 15),
                        const SizedBox(width: 7),
                        Text('My Location',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.steelBlue,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Address display / manual override
            const Text('Pickup Address', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final result = await showLocationSearch(
                  context,
                  initialQuery: widget.addressCtrl.text,
                  lat: widget.lat,
                  lng: widget.lng,
                );
                if (result != null) {
                  widget.onAddressSelected(result.address, result.lat, result.lng);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.lgBR,
                  border: Border.all(
                    color: widget.addressCtrl.text.isNotEmpty
                        ? AppColors.steelBlue.withAlpha(100)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.mapPin,
                        color: AppColors.muted, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.addressCtrl.text.isEmpty
                            ? 'Tap to search your pickup address'
                            : widget.addressCtrl.text,
                        style: AppTextStyles.body.copyWith(
                          color: widget.addressCtrl.text.isEmpty
                              ? AppColors.muted
                              : AppColors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.pencilSimple,
                        color: AppColors.muted, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Gate / Access Notes (optional)',
                style: AppTextStyles.label),
            const SizedBox(height: 8),
            AppTextField(
              controller: widget.notesCtrl,
              label: '',
              hint: 'e.g. Green gate, ring bell twice',
              prefixIcon: const Icon(PhosphorIconsRegular.notepad,
                  color: AppColors.muted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Review & Pay
// ─────────────────────────────────────────────────────────────────────────────

class _Step5Review extends StatelessWidget {
  const _Step5Review({
    required this.category,
    required this.binSize,
    required this.extraBags,
    required this.address,
    required this.isNow,
    required this.scheduledDate,
    required this.timePref,
    required this.frequency,
    required this.base,
    required this.extrasAmt,
    required this.total,
    required this.payMethod,
    required this.fade,
  });

  final String? category;
  final String binSize;
  final int extraBags;
  final String address;
  final bool isNow;
  final DateTime? scheduledDate;
  final String timePref;
  final String frequency;
  final double base;
  final double extrasAmt;
  final double total;
  final String payMethod;
  final Animation<double> fade;

  static const _payOptions = [
    {'key': 'CASH', 'label': 'Cash on Arrival', 'color': AppColors.success},
  ];

  String _dateLabel() {
    if (isNow) return 'Immediately';
    if (scheduledDate == null) return 'Not selected';
    final d = scheduledDate!;
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final tp = timePref == 'MORNING' ? '7–11am'
        : timePref == 'AFTERNOON' ? '12–4pm' : '4–7pm';
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} • $tp';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review & Pay', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Double-check your booking details',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                )),

            const SizedBox(height: 20),

            // Summary card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SummaryLine(
                    icon: PhosphorIconsRegular.recycle,
                    label: 'Category',
                    value: category?.replaceAll('_', ' ') ?? 'Household Waste',
                  ),
                  _SummaryLine(
                    icon: PhosphorIconsRegular.trashSimple,
                    label: 'Bin Size',
                    value: Fmt.binSizeLabel(binSize),
                  ),
                  if (extraBags > 0)
                    _SummaryLine(
                      icon: PhosphorIconsRegular.plus,
                      label: 'Extra Bags',
                      value: '$extraBags bag${extraBags > 1 ? 's' : ''}',
                    ),
                  _SummaryLine(
                    icon: PhosphorIconsRegular.clock,
                    label: 'Schedule',
                    value: _dateLabel(),
                  ),
                  if (!isNow && frequency != 'ONE_TIME')
                    _SummaryLine(
                      icon: PhosphorIconsRegular.repeat,
                      label: 'Frequency',
                      value: frequency == 'WEEKLY' ? 'Weekly'
                          : frequency == 'BIWEEKLY' ? 'Every 2 Weeks'
                          : 'Monthly',
                    ),
                  _SummaryLine(
                    icon: PhosphorIconsRegular.mapPin,
                    label: 'Address',
                    value: address,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.steelBlue.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(color: AppColors.steelBlue.withAlpha(60)),
              ),
              child: Column(
                children: [
                  _PriceRow(
                      label: 'Bin (${Fmt.binSizeLabel(binSize)})',
                      value: Fmt.currency(base)),
                  if (extrasAmt > 0) ...[
                    const SizedBox(height: 8),
                    _PriceRow(
                        label: 'Extra bags (×$extraBags)',
                        value: Fmt.currency(extrasAmt)),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: AppTextStyles.h4),
                      Text(Fmt.currency(total),
                          style: AppTextStyles.monoLg.copyWith(
                            color: AppColors.iceBlue,
                          )),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Payment Method', style: AppTextStyles.label),
            const SizedBox(height: 12),

            // Payment method tiles
            ..._payOptions.map((p) {
              final sel = payMethod == p['key'];
              final color = p['color'] as Color;
              return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: sel ? color.withAlpha(20) : AppColors.card,
                    borderRadius: AppRadius.lgBR,
                    border: Border.all(
                      color: sel ? color : AppColors.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: AppRadius.mdBR,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.money,
                          color: AppColors.success, size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p['label'] as String,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.success,
                            )),
                      ),
                      const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.success, size: 20),
                    ],
                  ),
                );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CountBtn extends StatelessWidget {
  const _CountBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.selectionClick();
        onTap!();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.steelBlue.withAlpha(25)
              : AppColors.border.withAlpha(40),
          borderRadius: AppRadius.mdBR,
          border: Border.all(
            color: enabled ? AppColors.steelBlue.withAlpha(60) : AppColors.border,
          ),
        ),
        child: Icon(icon,
            color: enabled ? AppColors.steelBlue : AppColors.muted,
            size: 18),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: AppRadius.mdBR,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? AppColors.white : AppColors.muted,
                  size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected ? AppColors.white : AppColors.muted,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
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
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    )),
                const SizedBox(height: 1),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StaticMapPin — non-interactive MapLibre preview with a single pin circle
// ─────────────────────────────────────────────────────────────────────────────

class _StaticMapPin extends StatefulWidget {
  const _StaticMapPin({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  State<_StaticMapPin> createState() => _StaticMapPinState();
}

class _StaticMapPinState extends State<_StaticMapPin> {
  MapLibreMapController? _ctrl;
  Circle? _pin;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_StaticMapPin old) {
    super.didUpdateWidget(old);
    if (_pin != null &&
        (old.lat != widget.lat || old.lng != widget.lng)) {
      _ctrl?.updateCircle(
        _pin!,
        CircleOptions(geometry: LatLng(widget.lat, widget.lng)),
      );
      _ctrl?.animateCamera(CameraUpdate.newLatLng(LatLng(widget.lat, widget.lng)));
    }
  }

  Future<void> _onStyleLoaded() async {
    if (_ctrl == null) return;
    _pin = await _ctrl!.addCircle(CircleOptions(
      geometry: LatLng(widget.lat, widget.lng),
      circleRadius: 14,
      circleColor: '#5483B3',
      circleOpacity: 0.9,
      circleStrokeWidth: 3,
      circleStrokeColor: '#C1E8FF',
      circleStrokeOpacity: 1.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: kMapStyleUrl,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.lat, widget.lng),
        zoom: 15.0,
      ),
      onMapCreated: (c) => _ctrl = c,
      onStyleLoadedCallback: _onStyleLoaded,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      doubleClickZoomEnabled: false,
      myLocationEnabled: false,
      compassEnabled: false,
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            )),
        Text(value,
            style: AppTextStyles.monoSm.copyWith(
              color: AppColors.textPrimary,
            )),
      ],
    );
  }
}
