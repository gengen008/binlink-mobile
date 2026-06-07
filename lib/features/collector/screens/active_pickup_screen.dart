import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
  
  LatLng get _pickupPos => LatLng(
        (widget.booking['pickupLat'] as num?)?.toDouble() ?? 5.6037,
        (widget.booking['pickupLng'] as num?)?.toDouble() ?? -0.1870,
      );

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

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          Positioned.fill(
            child: BinLinkMap(
              initialPosition: _pickupPos,
              pickupPosition: _pickupPos,
            ),
          ),

          // ── Header ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(PhosphorIconsRegular.arrowLeft)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.mdBR,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Pickup Detail', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(address, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showExceptionSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: const Icon(PhosphorIconsFill.warningCircle, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Sheet (Operational Console) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.sheetBR,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surface,
                        child: Text(Fmt.initials(hhName)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hhName, style: AppTextStyles.section),
                            Text(Fmt.categoryLabel(widget.booking['wasteCategory'] as String? ?? ''), style: AppTextStyles.meta),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => showChatSheet(context, bookingId: widget.booking['id'], myRole: 'COLLECTOR'),
                        icon: Icon(PhosphorIconsFill.chatCircle, color: AppColors.primary),
                      ),
                      IconButton(
                        onPressed: () => launchUrl(Uri.parse('tel:${widget.booking['household']?['phone'] ?? ''}')),
                        icon: Icon(PhosphorIconsFill.phone, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_currentStatus == 'ACCEPTED')
                    AppButton(
                      label: 'Start Trip',
                      onPressed: () async {
                        await prov.updateStatus(widget.booking['id'], 'en-route');
                        setState(() => _currentStatus = 'EN_ROUTE');
                      },
                    ),
                  if (_currentStatus == 'EN_ROUTE')
                    AppButton(
                      label: 'I Have Arrived',
                      onPressed: () async {
                        await prov.updateStatus(widget.booking['id'], 'arrived');
                        setState(() => _currentStatus = 'ARRIVED');
                      },
                    ),
                  if (_currentStatus == 'ARRIVED' || _currentStatus == 'COLLECTING') ...[
                    if (_beforePhoto == null)
                      AppButton(
                        label: _uploading ? 'Uploading...' : 'Take Before Photo',
                        icon: Image.asset(AppAssets.collectorCamera, width: 20, height: 20, color: Colors.white),
                        onPressed: _uploading ? null : () => _takePhoto('before'),
                      )
                    else if (_currentStatus == 'ARRIVED')
                      AppButton(
                        label: 'Start Collecting',
                        onPressed: () async {
                          await prov.updateStatus(widget.booking['id'], 'collecting');
                          setState(() => _currentStatus = 'COLLECTING');
                        },
                      )
                    else if (_afterPhoto == null)
                      AppButton(
                        label: _uploading ? 'Uploading...' : 'Take After Photo',
                        icon: Image.asset(AppAssets.collectorCamera, width: 20, height: 20, color: Colors.white),
                        onPressed: _uploading ? null : () => _takePhoto('after'),
                      )
                    else ...[
                      AppTextField(
                        controller: _weightCtrl,
                        label: 'Actual Weight (kg)',
                        hint: 'Enter collected weight',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Complete Pickup',
                        onPressed: () async {
                          final w = double.tryParse(_weightCtrl.text) ?? 0;
                          if (w <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid weight'))
                            );
                            return;
                          }
                          await prov.updateStatus(widget.booking['id'], 'complete', actualWeightKg: w);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
      builder: (context) => _ExceptionSheet(
        onReport: (reason, note) async {
          await context.read<CollectorProvider>().reportException(widget.booking['id'], reason, note);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pop(context); // Exit active pickup screen
          }
        },
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
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Exception', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text('Why are you unable to complete this pickup?', style: AppTextStyles.meta),
          const SizedBox(height: 24),
          ..._reasons.map((r) {
            final selected = _reason == r['value'];
            return InkWell(
              onTap: () => setState(() => _reason = r['value']),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.danger : AppColors.border,
                          width: selected ? 6 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(r['label']!, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          AppTextField(
            controller: _noteCtrl,
            label: 'Additional Note (Optional)',
            hint: 'Describe the issue...',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Submit Report',
            variant: AppButtonVariant.danger,
            onPressed: _reason == null ? null : () => widget.onReport(_reason!, _noteCtrl.text),
          ),
        ],
      ),
    );
  }
}
