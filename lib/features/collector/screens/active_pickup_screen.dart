import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/collector_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/l10n/strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/status_badge.dart';

class ActivePickupScreen extends StatefulWidget {
  const ActivePickupScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<ActivePickupScreen> createState() => _ActivePickupScreenState();
}

class _ActivePickupScreenState extends State<ActivePickupScreen> {
  final _picker = ImagePicker();

  XFile? _beforePhoto;
  XFile? _afterPhoto;
  bool _uploadingBefore = false;
  bool _uploadingAfter  = false;
  late String _currentStatus;
  final _weightCtrl = TextEditingController();

  MapLibreMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] as String? ?? 'ACCEPTED';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _onMapStyleLoaded() async {
    if (_mapCtrl == null) return;
    await _mapCtrl!.addCircle(CircleOptions(
      geometry: _pickupPos,
      circleRadius: 14,
      circleColor: '#7DA0CA',
      circleOpacity: 0.95,
      circleStrokeWidth: 3,
      circleStrokeColor: '#C1E8FF',
      circleStrokeOpacity: 1.0,
    ));
  }

  LatLng get _pickupPos => LatLng(
    (widget.booking['pickupLat'] as num?)?.toDouble() ?? 5.6037,
    (widget.booking['pickupLng'] as num?)?.toDouble() ?? -0.1870,
  );

  // ── Photo helpers ──────────────────────────────────────────────────────────

  Future<void> _pickPhoto(bool isBefore) async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (photo == null) return;
    setState(() {
      if (isBefore) {
        _beforePhoto = photo;
      } else {
        _afterPhoto = photo;
      }
    });
  }

  Future<bool> _uploadPhoto(String bookingId, XFile photo, String type) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: photo.name,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      await ApiClient.instance.post(
        '/api/bookings/$bookingId/photos',
        data: formData,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Status action handlers ─────────────────────────────────────────────────

  Future<void> _handleEnRoute(
    BuildContext ctx,
    CollectorProvider prov,
    String bookingId,
  ) async {
    if (_beforePhoto == null) {
      _snack(ctx, 'Take a Before photo first', AppColors.warning);
      return;
    }
    setState(() => _uploadingBefore = true);
    final ok = await _uploadPhoto(bookingId, _beforePhoto!, 'before');
    if (!ctx.mounted) return;
    if (!ok) {
      setState(() => _uploadingBefore = false);
      _snack(ctx, 'Photo upload failed — try again', AppColors.danger);
      return;
    }
    await prov.updateStatus(bookingId, 'en-route');
    if (!ctx.mounted) return;
    setState(() {
      _uploadingBefore = false;
      _currentStatus   = 'EN_ROUTE';
    });
  }

  Future<void> _handleArrived(
    CollectorProvider prov,
    String bookingId,
  ) async {
    await prov.updateStatus(bookingId, 'arrived');
    if (mounted) setState(() => _currentStatus = 'ARRIVED');
  }

  Future<void> _handleComplete(
    BuildContext ctx,
    CollectorProvider prov,
    String bookingId,
  ) async {
    if (_afterPhoto == null) {
      _snack(ctx, 'Take an After photo first', AppColors.warning);
      return;
    }
    final weightStr = _weightCtrl.text.trim();
    if (weightStr.isEmpty) {
      _snack(ctx, 'Enter the actual weight to complete', AppColors.warning);
      return;
    }
    final actualWeight = double.tryParse(weightStr);
    if (actualWeight == null || actualWeight <= 0) {
      _snack(ctx, 'Enter a valid weight in kg', AppColors.warning);
      return;
    }
    setState(() => _uploadingAfter = true);
    final ok = await _uploadPhoto(bookingId, _afterPhoto!, 'after');
    if (!ctx.mounted) return;
    if (!ok) {
      setState(() => _uploadingAfter = false);
      _snack(ctx, 'Photo upload failed — try again', AppColors.danger);
      return;
    }
    await prov.updateStatus(bookingId, 'complete', actualWeightKg: actualWeight);
    if (!ctx.mounted) return;
    setState(() {
      _uploadingAfter = false;
      _currentStatus  = 'COMPLETED';
    });
    _snack(ctx, 'Pickup completed! Great work!', AppColors.success);
    Navigator.pop(ctx);
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Exception sheet ────────────────────────────────────────────────────────

  void _showExceptionSheet(String bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExceptionSheet(
        onSubmit: (reason, note) {
          context.read<CollectorProvider>().reportException(bookingId, reason, note);
          Navigator.pop(context);
          _snack(context, 'Exception reported. Household notified.', AppColors.warning);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prov      = context.watch<CollectorProvider>();
    final bookingId = widget.booking['id'] as String;
    final address   = widget.booking['pickupAddress'] as String? ?? '';
    final amount    = (widget.booking['totalAmount'] as num?)?.toDouble() ?? 0;
    final hhPhone   = widget.booking['household']?['phone'] as String?;
    final hhName    = widget.booking['household']?['fullName'] as String? ?? 'Household';
    final isActive  = ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(_currentStatus);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // ── Header ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.white),
                    ),
                    const Expanded(child: Text('Active Pickup', style: AppTextStyles.h3)),
                    StatusBadge(status: _currentStatus, animate: true),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => showChatSheet(
                        context,
                        bookingId: widget.booking['id'] as String,
                        myRole: 'COLLECTOR',
                      ),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.steelBlue.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.steelBlue.withAlpha(60)),
                        ),
                        child: const Icon(PhosphorIconsFill.chatCircle,
                            color: AppColors.steelBlue, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Map ──
            SizedBox(
              height: 200,
              child: MapLibreMap(
                styleString: kMapStyleUrl,
                initialCameraPosition: CameraPosition(
                  target: _pickupPos,
                  zoom: 15.0,
                ),
                onMapCreated: (c) => _mapCtrl = c,
                onStyleLoadedCallback: _onMapStyleLoaded,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                doubleClickZoomEnabled: false,
                myLocationEnabled: false,
                compassEnabled: false,
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Household card
                    _HouseholdCard(
                      hhName: hhName,
                      address: address,
                      amount: amount,
                      binSize: widget.booking['binSize'] as String? ?? '',
                      paymentMethod: widget.booking['paymentMethod'] as String? ?? '',
                      phone: hhPhone,
                    ),

                    const SizedBox(height: 20),

                    // Photo verification section
                    _photoSection(),

                    const SizedBox(height: 20),

                    // Action buttons
                    ..._buildActions(context, prov, bookingId),

                    // Exception report (always visible during active jobs)
                    if (isActive) ...[
                      const SizedBox(height: 12),
                      _ExceptionButton(onTap: () => _showExceptionSheet(bookingId)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo section ──────────────────────────────────────────────────────────

  Widget _photoSection() {
    const showBefore = true; // always show before tile
    final showAfter  = ['ARRIVED', 'COMPLETED'].contains(_currentStatus);
    final canTakeBefore = _currentStatus == 'ACCEPTED';
    final canTakeAfter  = _currentStatus == 'ARRIVED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(PhosphorIconsRegular.camera, color: AppColors.skyBlue, size: 16),
            SizedBox(width: 6),
            Text('Verification Photos', style: AppTextStyles.label),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (showBefore)
              Expanded(
                child: _PhotoTile(
                  label: 'Before',
                  photo: _beforePhoto,
                  isRequired: canTakeBefore && _beforePhoto == null,
                  isActive: canTakeBefore,
                  onTap: canTakeBefore ? () => _pickPhoto(true) : null,
                ),
              ),
            if (showBefore && showAfter) const SizedBox(width: 12),
            if (showAfter)
              Expanded(
                child: _PhotoTile(
                  label: 'After',
                  photo: _afterPhoto,
                  isRequired: canTakeAfter && _afterPhoto == null,
                  isActive: canTakeAfter,
                  onTap: canTakeAfter ? () => _pickPhoto(false) : null,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  List<Widget> _buildActions(
    BuildContext context,
    CollectorProvider prov,
    String bookingId,
  ) {
    switch (_currentStatus) {
      case 'ACCEPTED':
        return [
          Opacity(
            opacity: _beforePhoto != null ? 1.0 : 0.45,
            child: AppButton(
              label: S.of(context).startRoute,
              loading: _uploadingBefore,
              onPressed: _beforePhoto != null && !_uploadingBefore
                  ? () => _handleEnRoute(context, prov, bookingId)
                  : null,
              icon: const Icon(PhosphorIconsFill.navigationArrow, color: AppColors.white, size: 20),
            ),
          ),
          if (_beforePhoto == null) ...[
            const SizedBox(height: 8),
            _PhotoRequiredHint(label: S.of(context).takeBefore),
          ],
        ];

      case 'EN_ROUTE':
        return [
          AppButton(
            label: S.of(context).markArrived,
            onPressed: () => _handleArrived(prov, bookingId),
            icon: const Icon(PhosphorIconsFill.mapPin, color: AppColors.white, size: 20),
          ),
        ];

      case 'ARRIVED':
        return [
          // Actual weight input — required before completing
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.scales, color: AppColors.skyBlue, size: 15),
                    const SizedBox(width: 6),
                    const Text('Actual Weight (kg)', style: AppTextStyles.label),
                    const SizedBox(width: 4),
                    Text('*required', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.mono,
                  decoration: InputDecoration(
                    hintText: 'e.g. 85',
                    hintStyle: AppTextStyles.caption,
                    suffixText: 'kg',
                    suffixStyle: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.deepOcean,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.steelBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: _afterPhoto != null ? 1.0 : 0.45,
            child: AppButton(
              label: S.of(context).completePickup,
              loading: _uploadingAfter,
              onPressed: _afterPhoto != null && !_uploadingAfter
                  ? () => _handleComplete(context, prov, bookingId)
                  : null,
              icon: const Icon(PhosphorIconsFill.checkCircle, color: AppColors.white, size: 20),
            ),
          ),
          if (_afterPhoto == null) ...[
            const SizedBox(height: 8),
            _PhotoRequiredHint(label: S.of(context).takeAfter),
          ],
        ];

      case 'COMPLETED':
        return [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withAlpha(60)),
            ),
            child: const Row(
              children: [
                Icon(PhosphorIconsFill.checkCircle, color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Pickup completed successfully!', style: AppTextStyles.h4),
                ),
              ],
            ),
          ),
        ];

      default:
        return [];
    }
  }
}

// ── Household card ─────────────────────────────────────────────────────────

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({
    required this.hhName,
    required this.address,
    required this.amount,
    required this.binSize,
    required this.paymentMethod,
    this.phone,
  });
  final String hhName;
  final String address;
  final double amount;
  final String binSize;
  final String paymentMethod;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(Fmt.initials(hhName), style: AppTextStyles.bodyMedium),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hhName, style: AppTextStyles.h4),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin, color: AppColors.skyBlue, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(address,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (phone != null)
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success.withAlpha(80)),
                    ),
                    child: const Icon(PhosphorIconsFill.phone, color: AppColors.success, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: Fmt.binSizeLabel(binSize),
                icon: PhosphorIconsFill.trashSimple,
                color: AppColors.steelBlue,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                label: Fmt.currency(amount),
                icon: PhosphorIconsFill.coins,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                label: Fmt.paymentMethodLabel(paymentMethod),
                icon: PhosphorIconsRegular.deviceMobile,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Photo tile ─────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.isRequired,
    required this.isActive,
    this.photo,
    this.onTap,
  });
  final String label;
  final bool isRequired;
  final bool isActive;
  final XFile? photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasTaken = photo != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        decoration: BoxDecoration(
          color: hasTaken
              ? AppColors.success.withAlpha(15)
              : isActive
                  ? AppColors.steelBlue.withAlpha(20)
                  : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasTaken
                ? AppColors.success.withAlpha(120)
                : isActive
                    ? AppColors.steelBlue.withAlpha(120)
                    : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Photo thumbnail or placeholder icon
            if (hasTaken)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(photo!.path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? PhosphorIconsFill.camera
                          : PhosphorIconsRegular.camera,
                      color: isActive ? AppColors.steelBlue : AppColors.muted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive ? 'Tap to capture' : 'Pending',
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? AppColors.steelBlue : AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom label bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: hasTaken
                      ? AppColors.success.withAlpha(200)
                      : AppColors.midnightNavy.withAlpha(180),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasTaken) ...[
                      const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.white, size: 11),
                      const SizedBox(width: 4),
                    ] else if (isRequired) ...[
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '$label Photo',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo required hint ────────────────────────────────────────────────────

class _PhotoRequiredHint extends StatelessWidget {
  const _PhotoRequiredHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.info, color: AppColors.warning, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }
}

// ── Exception button ───────────────────────────────────────────────────────

class _ExceptionButton extends StatelessWidget {
  const _ExceptionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withAlpha(80)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.warning, color: AppColors.danger, size: 16),
            SizedBox(width: 8),
            Text('Report Exception', style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: AppColors.danger,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Exception sheet ────────────────────────────────────────────────────────

class _ExceptionSheet extends StatefulWidget {
  const _ExceptionSheet({required this.onSubmit});
  final void Function(String reason, String? note) onSubmit;

  @override
  State<_ExceptionSheet> createState() => _ExceptionSheetState();
}

class _ExceptionSheetState extends State<_ExceptionSheet> {
  String? _selectedReason;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  static const _reasons = [
    ('GATE_LOCKED',  'Gate Locked',              PhosphorIconsRegular.lock),
    ('BIN_NOT_READY','Bin Not Ready',             PhosphorIconsRegular.trashSimple),
    ('OVERLOADED',   'Overfilled / Overloaded',   PhosphorIconsRegular.warning),
    ('HAZARDOUS',    'Hazardous Material',         PhosphorIconsRegular.skull),
    ('NO_ACCESS',    'No Access to Property',      PhosphorIconsRegular.prohibit),
    ('OTHER',        'Other',                      PhosphorIconsRegular.dotsSixVertical),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
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
      child: Column(
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

          // Title row
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.danger.withAlpha(80)),
                ),
                child: const Icon(PhosphorIconsFill.warning, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report Exception', style: AppTextStyles.h3),
                  Text('What issue did you encounter?', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),

          // Reason tiles
          ..._reasons.map((r) {
            final isSelected = _selectedReason == r.$1;
            return GestureDetector(
              onTap: () => setState(() => _selectedReason = r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.danger.withAlpha(20)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.danger.withAlpha(140)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.$3,
                        color: isSelected ? AppColors.danger : AppColors.muted,
                        size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.$2, style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.danger : AppColors.textPrimary,
                      )),
                    ),
                    if (isSelected)
                      const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.danger, size: 18),
                  ],
                ),
              ),
            );
          }),

          // Note input (only for OTHER)
          if (_selectedReason == 'OTHER') ...[
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              style: AppTextStyles.bodyMedium,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
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
            const SizedBox(height: 4),
          ],

          const SizedBox(height: 20),

          // Submit button
          GestureDetector(
            onTap: _selectedReason != null && !_submitting
                ? () {
                    setState(() => _submitting = true);
                    widget.onSubmit(
                      _selectedReason!,
                      _selectedReason == 'OTHER'
                          ? _noteCtrl.text.trim()
                          : null,
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: _selectedReason != null
                    ? AppColors.danger
                    : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedReason != null
                      ? AppColors.danger
                      : AppColors.border,
                ),
                boxShadow: _selectedReason != null
                    ? [BoxShadow(
                        color: AppColors.danger.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )]
                    : null,
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white,
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedReason != null
                              ? AppColors.white
                              : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: color),
                textAlign: TextAlign.center,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}
