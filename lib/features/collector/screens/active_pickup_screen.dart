import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/collector_provider.dart';
import '../components/navigation_overlay.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/chat_sheet.dart';
import '../../../shared/widgets/binlink_map.dart';

class ActivePickupScreen extends StatefulWidget {
  const ActivePickupScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<ActivePickupScreen> createState() => _ActivePickupScreenState();
}

class _ActivePickupScreenState extends State<ActivePickupScreen> {
  late String _currentStatus;
  final _weightCtrl = TextEditingController();
  final _picker = ImagePicker();
  
  String? _beforePhoto;
  String? _afterPhoto;
  bool _uploading = false;
  
  ll.LatLng? get _pickupPos {
    final lat = (widget.booking['pickupLat'] as num?)?.toDouble();
    final lng = (widget.booking['pickupLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return ll.LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] as String? ?? 'ACCEPTED';
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final hhName = widget.booking['household']?['fullName'] as String? ?? 'Household';
    final address = widget.booking['pickupAddress'] as String? ?? '';

    final isNavigating = _currentStatus == 'EN_ROUTE';

    final pickup = _pickupPos;
    if (pickup == null) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(title: const Text('Invalid Pickup Location')),
        body: const Center(child: Text('Error: Pickup coordinates missing', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // ── Map ──
          Positioned.fill(
            child: BinLinkMap(
              initialPosition: pickup,
              pickupPosition: pickup,
              isNavigating: isNavigating,
              myLocation: prov.currentLat != null ? ll.LatLng(prov.currentLat!, prov.currentLng!) : null,
              myHeading: prov.currentHeading ?? 0.0,
            ),
          ),

          // ── Premium Header ──
          if (isNavigating)
            NavigationOverlay(
              instructionText: 'Follow the green line to destination',
              distanceMeters: (widget.booking['distanceMeters'] as num?)?.toInt() ?? 0,
              maneuver: 'straight',
              etaMinutes: ((widget.booking['eta'] as num?)?.toInt() ?? 0) ~/ 60,
              distanceKm: (widget.booking['distanceMeters'] as num? ?? 0) / 1000.0,
              speedLimitKph: 60,
              currentSpeedKph: prov.currentSpeedKph,
            )
          else
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              child: FadeInDown(
                child: Row(
                  children: [
                    _RoundBackBtn(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.premiumBlack,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ACTIVE PICKUP', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            Text(address, style: AppTextStyles.bodySmall.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Exception Trigger ──
          if (!isNavigating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: _RoundActionBtn(
                icon: PhosphorIconsFill.warningCircle,
                color: AppColors.danger,
                onTap: () => _showExceptionSheet(context),
              ),
            ),

          // ── Operational Console ──
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                decoration: const BoxDecoration(
                  color: AppColors.premiumBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, -10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Household Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.premiumBlack,
                            child: Text(Fmt.initials(hhName), style: AppTextStyles.h3.copyWith(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hhName, style: AppTextStyles.h2.copyWith(color: Colors.white)),
                              Text(Fmt.categoryLabel(widget.booking['wasteCategory'] as String? ?? ''), style: AppTextStyles.label.copyWith(color: Colors.white54)),
                            ],
                          ),
                        ),
                        _RoundActionBtn(
                          icon: PhosphorIconsFill.chatCircle,
                          onTap: () => showChatSheet(context, bookingId: widget.booking['id'], myRole: 'COLLECTOR'),
                        ),
                        const SizedBox(width: 12),
                        _RoundActionBtn(
                          icon: PhosphorIconsFill.phone,
                          onTap: () => launchUrl(Uri.parse('tel:${widget.booking['household']?['phone'] ?? ''}')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Dynamic Status Buttons
                    _buildStatusActions(prov),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(CollectorProvider prov) {
    switch (_currentStatus) {
      case 'ACCEPTED':
        return AppButton(
          label: 'START TRIP',
          onPressed: () async {
            await prov.updateStatus(widget.booking['id'], 'en-route');
            setState(() => _currentStatus = 'EN_ROUTE');
          },
        );
      case 'EN_ROUTE':
      case 'ON_THE_WAY':
        return AppButton(
          label: 'I HAVE ARRIVED',
          onPressed: () async {
            await prov.updateStatus(widget.booking['id'], 'arrived');
            setState(() => _currentStatus = 'ARRIVED');
          },
        );
      case 'ARRIVED':
      case 'COLLECTING':
        return Column(
          children: [
            if (_beforePhoto == null)
              AppButton(
                label: _uploading ? 'UPLOADING...' : 'TAKE BEFORE PHOTO',
                icon: const Icon(PhosphorIconsFill.camera, color: Colors.white),
                onPressed: _uploading ? null : () => _takePhoto('before'),
              )
            else if (_currentStatus == 'ARRIVED')
              AppButton(
                label: 'START COLLECTING',
                onPressed: () async {
                  await prov.updateStatus(widget.booking['id'], 'collecting');
                  setState(() => _currentStatus = 'COLLECTING');
                },
              )
            else if (_afterPhoto == null)
              AppButton(
                label: _uploading ? 'UPLOADING...' : 'TAKE AFTER PHOTO',
                icon: const Icon(PhosphorIconsFill.camera, color: Colors.white),
                onPressed: _uploading ? null : () => _takePhoto('after'),
              )
            else ...[
              AppTextField(
                controller: _weightCtrl,
                label: 'Actual Weight (kg)',
                hint: '0.0',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'COMPLETE PICKUP',
                onPressed: () async {
                  final w = double.tryParse(_weightCtrl.text) ?? 0;
                  if (w <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid weight')));
                    return;
                  }
                  await prov.updateStatus(widget.booking['id'], 'complete', actualWeightKg: w);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _takePhoto(String type) async {
    final prov = context.read<CollectorProvider>();
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file == null) return;

    setState(() => _uploading = true);
    final url = await prov.uploadPhoto(widget.booking['id'], type, file.path);
    setState(() {
      _uploading = false;
      if (url != null) {
        if (type == 'before') _beforePhoto = url;
        if (type == 'after') _afterPhoto = url;
      }
    });
  }

  void _showExceptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExceptionSheet(
        onReport: (reason, note) async {
          await context.read<CollectorProvider>().reportException(widget.booking['id'], reason, note);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pop(context); 
          }
        },
      ),
    );
  }
}

class _RoundBackBtn extends StatelessWidget {
  const _RoundBackBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: AppColors.premiumBlack, shape: BoxShape.circle),
        child: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white, size: 24),
      ),
    );
  }
}

class _RoundActionBtn extends StatelessWidget {
  const _RoundActionBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color ?? AppColors.premiumBlack, shape: BoxShape.circle, border: color == null ? Border.all(color: Colors.white10) : null),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}

class _ExceptionSheet extends StatefulWidget {
  const _ExceptionSheet({required this.onReport});
  final Function(String, String?) onReport;

  @override
  State<_ExceptionSheet> createState() => _ExceptionSheetState();
}

class _ExceptionSheetState extends State<_ExceptionSheet> {
  String? _reason;
  final _noteCtrl = TextEditingController();

  final _reasons = [
    {'label': 'Gate Locked', 'value': 'GATE_LOCKED'},
    {'label': 'Bin Not Ready', 'value': 'BIN_NOT_READY'},
    {'label': 'Overfilled Load', 'value': 'OVERFILLED'},
    {'label': 'Hazardous Material', 'value': 'HAZARDOUS'},
    {'label': 'No Access', 'value': 'NO_ACCESS'},
    {'label': 'Other', 'value': 'OTHER'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.premiumBlack, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Problem', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Select a reason for cancellation', style: AppTextStyles.label.copyWith(color: Colors.white54)),
          const SizedBox(height: 32),
          ..._reasons.map((r) {
            final selected = _reason == r['value'];
            return GestureDetector(
              onTap: () => setState(() => _reason = r['value']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.danger.withAlpha(20) : Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? AppColors.danger : Colors.white10),
                ),
                child: Row(
                  children: [
                    Text(r['label']!, style: AppTextStyles.h4.copyWith(color: selected ? AppColors.danger : Colors.white)),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle, color: AppColors.danger, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          AppTextField(
            controller: _noteCtrl,
            label: 'Additional details',
            hint: 'Describe the situation...',
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'CANCEL PICKUP',
            variant: AppButtonVariant.danger,
            onPressed: _reason == null ? null : () => widget.onReport(_reason!, _noteCtrl.text),
          ),
        ],
      ),
    );
  }
}
