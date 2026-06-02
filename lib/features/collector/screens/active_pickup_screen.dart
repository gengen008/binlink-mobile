import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_style.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_badge.dart';

class ActivePickupScreen extends StatefulWidget {
  const ActivePickupScreen({super.key, required this.booking});
  final Map<String, dynamic> booking;

  @override
  State<ActivePickupScreen> createState() => _ActivePickupScreenState();
}

class _ActivePickupScreenState extends State<ActivePickupScreen> {
  final Completer<GoogleMapController> _mapCtrl = Completer();

  void _onMapCreated(GoogleMapController ctrl) {
    if (!_mapCtrl.isCompleted) _mapCtrl.complete(ctrl);
  }

  LatLng get _pickupPos => LatLng(
    (widget.booking['pickupLat'] as num?)?.toDouble() ?? 5.6037,
    (widget.booking['pickupLng'] as num?)?.toDouble() ?? -0.1870,
  );

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();
    final status = widget.booking['status'] as String? ?? 'ACCEPTED';
    final bookingId = widget.booking['id'] as String;
    final address = widget.booking['pickupAddress'] as String? ?? '';
    final amount = (widget.booking['totalAmount'] as num?)?.toDouble() ?? 0;
    final householdPhone = widget.booking['household']?['phone'] as String?;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: 'Pickup: $address'),
      ),
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
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
                    StatusBadge(status: status, animate: true),
                  ],
                ),
              ),
            ),

            // Google Map
            SizedBox(
              height: 240,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _pickupPos,
                  zoom: 15,
                ),
                style: kDarkMapStyle,
                markers: markers,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),

            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Household info card
                    Container(
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
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    Fmt.initials(widget.booking['household']?['fullName'] as String?),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.booking['household']?['fullName'] as String? ?? 'Household',
                                      style: AppTextStyles.h4,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(PhosphorIconsRegular.mapPin, color: AppColors.skyBlue, size: 13),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(address,
                                              style: AppTextStyles.caption,
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (householdPhone != null)
                                GestureDetector(
                                  onTap: () => launchUrl(Uri.parse('tel:$householdPhone')),
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
                                label: Fmt.binSizeLabel(widget.booking['binSize'] as String? ?? ''),
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
                                label: Fmt.paymentMethodLabel(widget.booking['paymentMethod'] as String? ?? ''),
                                icon: PhosphorIconsRegular.deviceMobile,
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    ..._actions(context, prov, status, bookingId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    CollectorProvider prov,
    String status,
    String bookingId,
  ) {
    switch (status) {
      case 'ACCEPTED':
        return [
          AppButton(
            label: 'Start Navigation (En Route)',
            onPressed: () => prov.updateStatus(bookingId, 'en-route'),
            icon: const Icon(PhosphorIconsFill.navigationArrow, color: AppColors.white, size: 20),
          ),
        ];
      case 'EN_ROUTE':
        return [
          AppButton(
            label: 'Mark as Arrived',
            onPressed: () => prov.updateStatus(bookingId, 'arrived'),
            icon: const Icon(PhosphorIconsFill.mapPin, color: AppColors.white, size: 20),
          ),
        ];
      case 'ARRIVED':
        return [
          AppButton(
            label: 'Complete Pickup',
            onPressed: () async {
              await prov.updateStatus(bookingId, 'complete');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pickup completed!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(PhosphorIconsFill.checkCircle, color: AppColors.white, size: 20),
          ),
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
            Text(label, style: AppTextStyles.caption.copyWith(color: color),
                textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
