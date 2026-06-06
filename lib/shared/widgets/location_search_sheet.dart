import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/services/places_service.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LocationResult {
  final String address;
  final double lat;
  final double lng;
  const LocationResult({required this.address, required this.lat, required this.lng});
}

/// Opens a full-screen search sheet for location lookup.
/// Returns a [LocationResult] or null if cancelled.
Future<LocationResult?> showLocationSearch(
  BuildContext context, {
  String? initialQuery,
  double lat = 5.6037,
  double lng = -0.1870,
}) {
  return showModalBottomSheet<LocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LocationSearchSheet(
      initialQuery: initialQuery,
      userLat: lat,
      userLng: lng,
    ),
  );
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({
    this.initialQuery,
    required this.userLat,
    required this.userLng,
  });
  final String? initialQuery;
  final double userLat;
  final double userLng;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<PlacePrediction> _results = [];
  bool _searching = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await PlacesService.autocomplete(
        value,
        lat: widget.userLat,
        lng: widget.userLng,
      );
      if (mounted) setState(() { _results = results; _searching = false; });
    });
  }

  Future<void> _selectPrediction(PlacePrediction p) async {
    HapticFeedback.selectionClick();
    // TomTom / Nominatim predictions already include lat/lng — use directly
    if (p.lat != null && p.lng != null) {
      Navigator.pop(context, LocationResult(
        address: p.fullText,
        lat: p.lat!,
        lng: p.lng!,
      ));
      return;
    }
    // Fallback: detail lookup (legacy path)
    setState(() => _searching = true);
    final detail = await PlacesService.getDetail(p.placeId);
    if (!mounted) return;
    Navigator.pop(context, LocationResult(
      address: detail?.address ?? p.fullText,
      lat: detail?.lat ?? widget.userLat,
      lng: detail?.lng ?? widget.userLng,
    ));
  }

  Future<void> _useCurrentLocation() async {
    HapticFeedback.mediumImpact();
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        Navigator.pop(context, LocationResult(
          address: address ?? 'Current Location',
          lat: pos.latitude,
          lng: pos.longitude,
        ));
      }
    } else {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: AppColors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Search Location', style: AppTextStyles.h4),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(100)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(30),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: _onChanged,
                style: AppTextStyles.body.copyWith(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search area, street, landmark...',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _searching
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(PhosphorIconsRegular.magnifyingGlass,
                            color: AppColors.primary, size: 18),
                  ),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _ctrl.clear();
                            setState(() { _results = []; });
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(PhosphorIconsRegular.x,
                                color: AppColors.muted, size: 16),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Use current location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: GestureDetector(
              onTap: _locating ? null : _useCurrentLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    _locating
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary))
                        : const Icon(PhosphorIconsFill.crosshair,
                            color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Use my current location',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            )),
                        Text('Auto-detect GPS location',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('RESULTS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Results list
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 24),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Divider(height: 1, color: AppColors.border),
              ),
              itemBuilder: (_, i) {
                final p = _results[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectPrediction(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(PhosphorIconsRegular.mapPin,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.mainText,
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (p.secondaryText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(p.secondaryText,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                        const Icon(PhosphorIconsRegular.arrowUpLeft,
                            color: AppColors.muted, size: 14),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
