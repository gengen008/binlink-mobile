import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../providers/collector_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/binlink_map.dart';
import '../../../shared/widgets/chat_sheet.dart';

class ActivePickupScreen extends StatefulWidget {
  const ActivePickupScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<ActivePickupScreen> createState() => _ActivePickupScreenState();
}

class _ActivePickupScreenState extends State<ActivePickupScreen> {
  String _currentStatus = '';
  String? _beforePhoto;
  String? _afterPhoto;
  bool _uploading = false;
  final _weightCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] as String? ?? 'ACCEPTED';
    _beforePhoto = widget.booking['beforePhoto'];
    _afterPhoto = widget.booking['afterPhoto'];
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final hhName = widget.booking['household']?['fullName'] as String? ?? 'Household';
    final lat = (widget.booking['pickupLat'] as num?)?.toDouble() ?? 0.0;
    final lng = (widget.booking['pickupLng'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.premiumBlack,
      body: Stack(
        children: [
          // ── Map ──
          Positioned.fill(
            child: BinLinkMap(
              initialPosition: ll.LatLng(lat, lng),
              pickupPosition: ll.LatLng(lat, lng),
              myLocationEnabled: true,
            ),
          ),

          // ── Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: _RoundBackBtn(onTap: () => Navigator.pop(context)),
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
                    // ── Status Progress Bar ──
                    _StatusProgressBar(status: _currentStatus),
                    const SizedBox(height: 24),

                    // Household Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: AppColors.primary.withAlpha(50), shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.premiumBlack,
                            child: Text(Fmt.initials(hhName), style: AppTextStyles.h3.copyWith(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hhName, style: AppTextStyles.h3.copyWith(color: Colors.white)),
                              Text(Fmt.categoryLabel(widget.booking['wasteCategory'] as String? ?? ''), style: AppTextStyles.label.copyWith(color: Colors.white54)),
                            ],
                          ),
                        ),
                        _RoundActionBtn(
                          icon: LucideIcons.messageCircle,
                          onTap: () => showChatSheet(context, bookingId: widget.booking['id'], myRole: 'COLLECTOR'),
                        ),
                        const SizedBox(width: 12),
                        _RoundActionBtn(
                          icon: LucideIcons.phone,
                          onTap: () => launchUrl(Uri.parse('tel:${widget.booking['household']?['phone'] ?? ''}')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),

                    // Action Area
                    _buildActions(prov),

                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => _showExceptionSheet(context),
                      child: Text('REPORT A PROBLEM', style: AppTextStyles.label.copyWith(color: AppColors.danger, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(CollectorProvider prov) {
    switch (_currentStatus) {
      case 'ACCEPTED':
        return AppButton(
          label: 'START NAVIGATION',
          icon: const Icon(LucideIcons.navigation, color: Colors.white),
          onPressed: () => launchUrl(Uri.parse('google.navigation:q=${widget.booking['pickupLat']},${widget.booking['pickupLng']}')),
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
        final step = _afterPhoto != null ? 4 : (_currentStatus == 'COLLECTING' ? 3 : (_beforePhoto != null ? 2 : 1));
        return Column(
          children: [
            _CollectionStepper(currentStep: step),
            const SizedBox(height: 32),
            if (_beforePhoto == null)
              AppButton(
                label: _uploading ? 'UPLOADING...' : 'TAKE BEFORE PHOTO',
                icon: const Icon(LucideIcons.camera, color: Colors.white),
                onPressed: _uploading ? null : () => _takePhoto('before'),
              )
            else ...[
              _PhotoThumbnail(url: _beforePhoto!, label: 'BEFORE PICKUP'),
              const SizedBox(height: 16),
              if (_currentStatus == 'ARRIVED')
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
                  icon: const Icon(LucideIcons.camera, color: Colors.white),
                  onPressed: _uploading ? null : () => _takePhoto('after'),
                )
              else ...[
                _PhotoThumbnail(url: _afterPhoto!, label: 'AFTER PICKUP'),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _weightCtrl,
                  label: 'Actual Weight',
                  hint: 'Enter weight in kg',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(LucideIcons.scale, color: Colors.white70),
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text('kg', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'COMPLETE PICKUP',
                  onPressed: () async {
                    final w = double.tryParse(_weightCtrl.text) ?? 0;
                    if (w <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid weight')),
                      );
                      return;
                    }
                    await prov.updateStatus(widget.booking['id'], 'complete', actualWeightKg: w);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
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
        child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
      ),
    );
  }
}

class _RoundActionBtn extends StatelessWidget {
  const _RoundActionBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withAlpha(10), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.url, required this.label});
  final String url;
  final String label;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
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
                    if (selected) const Icon(LucideIcons.circleCheck, color: AppColors.danger, size: 20),
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

class _StatusProgressBar extends StatelessWidget {
  const _StatusProgressBar({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final stages = ['ACCEPTED', 'EN_ROUTE', 'ARRIVED', 'COLLECTING'];
    int currentIndex = stages.indexOf(status);
    if (currentIndex == -1) {
      if (status == 'COMPLETED' || status == 'COLLECTED') currentIndex = stages.length;
      else currentIndex = 0;
    }

    return Column(
      children: [
        Row(
          children: List.generate(stages.length, (i) {
            final isActive = i <= currentIndex;
            final isLast = i == stages.length - 1;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (!isLast) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Accepted', style: AppTextStyles.label.copyWith(color: currentIndex >= 0 ? Colors.white : Colors.white38, fontSize: 10)),
            Text('On Way', style: AppTextStyles.label.copyWith(color: currentIndex >= 1 ? Colors.white : Colors.white38, fontSize: 10)),
            Text('Arrived', style: AppTextStyles.label.copyWith(color: currentIndex >= 2 ? Colors.white : Colors.white38, fontSize: 10)),
            Text('Collecting', style: AppTextStyles.label.copyWith(color: currentIndex >= 3 ? Colors.white : Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _CollectionStepper extends StatelessWidget {
  const _CollectionStepper({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Step(label: 'PHOTO 1', isDone: currentStep > 1, isCurrent: currentStep == 1),
        _StepConnector(isDone: currentStep > 1),
        _Step(label: 'COLLECT', isDone: currentStep > 2, isCurrent: currentStep == 2),
        _StepConnector(isDone: currentStep > 2),
        _Step(label: 'PHOTO 2', isDone: currentStep > 3, isCurrent: currentStep == 3),
        _StepConnector(isDone: currentStep > 3),
        _Step(label: 'WEIGHT',  isDone: currentStep > 4, isCurrent: currentStep == 4),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.isDone, required this.isCurrent});
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.success : (isCurrent ? AppColors.primary : Colors.white12);
    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: isDone ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isDone ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.small.copyWith(fontSize: 8, color: isCurrent || isDone ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.isDone});
  final bool isDone;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isDone ? AppColors.success : Colors.white12,
      ),
    );
  }
}
