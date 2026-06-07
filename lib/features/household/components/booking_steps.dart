import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/date_picker_row.dart';

// ── Waste categories ──────────────────────────────────────────────────────────

class WasteCategory {
  const WasteCategory({
    required this.key,
    required this.label,
    required this.image,
    required this.color,
    required this.desc,
  });
  final String key;
  final String label;
  final String image; // PNG asset path
  final Color color;
  final String desc;
}

final List<WasteCategory> kCategories = [
  WasteCategory(
    key: 'HOUSEHOLD',
    label: 'Household',
    image: AppAssets.trashBin,
    color: AppColors.primary,
    desc: 'General home rubbish',
  ),
  const WasteCategory(
    key: 'PLASTIC',
    label: 'Plastic / Glass',
    image: AppAssets.recycleBin,
    color: Color(0xFF3B82F6),
    desc: 'Bottles, bags, containers',
  ),
  const WasteCategory(
    key: 'ORGANIC',
    label: 'Organic',
    image: AppAssets.leaf,
    color: Color(0xFF10B981),
    desc: 'Food scraps, garden waste',
  ),
  const WasteCategory(
    key: 'EWASTE',
    label: 'E-Waste',
    image: AppAssets.laptop,
    color: Color(0xFF8B5CF6),
    desc: 'Electronics, batteries',
  ),
  const WasteCategory(
    key: 'GLASS',
    label: 'Glass / Metal',
    image: AppAssets.bottle,
    color: Color(0xFF0EA5E9),
    desc: 'Bottles, cans, scrap',
  ),
  const WasteCategory(
    key: 'CONSTRUCTION',
    label: 'Construction',
    image: AppAssets.construction,
    color: Color(0xFFB45309),
    desc: 'Debris, wood, tiles',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Category
// ─────────────────────────────────────────────────────────────────────────────

class StepCategory extends StatelessWidget {
  const StepCategory({super.key, required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you disposing?', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Select the primary waste type', style: AppTextStyles.body),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: kCategories.length,
            itemBuilder: (context, i) {
              final cat = kCategories[i];
              final isSelected = selected == cat.key;
              return InkWell(
                onTap: () => onSelect(cat.key),
                borderRadius: AppRadius.mdBR,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color.withAlpha(20) : Colors.white,
                    borderRadius: AppRadius.mdBR,
                    border: Border.all(
                      color: isSelected ? cat.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(cat.image, width: 40, height: 40),
                      const SizedBox(height: 12),
                      Text(cat.label, style: AppTextStyles.bodyMedium),
                      Text(cat.desc, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Volume
// ─────────────────────────────────────────────────────────────────────────────

class StepVolume extends StatelessWidget {
  const StepVolume({
    super.key,
    required this.binSize,
    required this.extraBags,
    required this.onBinSize,
    required this.onExtraBags,
  });
  final String binSize;
  final int extraBags;
  final ValueChanged<String> onBinSize;
  final ValueChanged<int> onExtraBags;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose bin size', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          _BinOption(
            label: 'Small Bin',
            desc: 'Up to 50kg',
            size: 'SMALL',
            current: binSize,
            onTap: onBinSize,
          ),
          _BinOption(
            label: 'Medium Bin',
            desc: 'Up to 100kg',
            size: 'MEDIUM',
            current: binSize,
            onTap: onBinSize,
          ),
          _BinOption(
            label: 'Large Bin',
            desc: 'Up to 200kg',
            size: 'LARGE',
            current: binSize,
            onTap: onBinSize,
          ),
          const SizedBox(height: 32),
          Text('Extra bags', style: AppTextStyles.section),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBR,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.shoppingBag, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Number of extra bags')),
                IconButton(
                  onPressed: extraBags > 0 ? () => onExtraBags(extraBags - 1) : null,
                  icon: const Icon(PhosphorIconsRegular.minusCircle),
                ),
                Text('$extraBags', style: AppTextStyles.bodyMedium),
                IconButton(
                  onPressed: () => onExtraBags(extraBags + 1),
                  icon: const Icon(PhosphorIconsRegular.plusCircle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BinOption extends StatelessWidget {
  const _BinOption({
    required this.label,
    required this.desc,
    required this.size,
    required this.current,
    required this.onTap,
  });
  final String label;
  final String desc;
  final String size;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = current == size;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onTap(size),
        borderRadius: AppRadius.mdBR,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(15) : Colors.white,
            borderRadius: AppRadius.mdBR,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium),
                    Text(desc, style: AppTextStyles.meta),
                  ],
                ),
              ),
              if (isSelected)
                Icon(PhosphorIconsFill.checkCircle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Photos
// ─────────────────────────────────────────────────────────────────────────────

class StepPhotos extends StatelessWidget {
  const StepPhotos({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });
  final List<XFile> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add photos (Optional)', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Help the collector estimate the volume.', style: AppTextStyles.body),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...List.generate(photos.length, (i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.mdBR,
                      child: Image.file(File(photos[i].path), width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(PhosphorIconsRegular.xCircle, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              InkWell(
                onTap: onAdd,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdBR,
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: const Icon(PhosphorIconsRegular.camera, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4: Schedule
// ─────────────────────────────────────────────────────────────────────────────

class StepSchedule extends StatelessWidget {
  const StepSchedule({
    super.key,
    required this.isNow,
    required this.scheduledDate,
    required this.onNowChanged,
    required this.onDateChanged,
  });
  final bool isNow;
  final DateTime? scheduledDate;
  final ValueChanged<bool> onNowChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When to pickup?', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          _ScheduleOption(
            label: 'As soon as possible',
            desc: 'Typically arrives in 15-30 mins',
            active: isNow,
            onTap: () => onNowChanged(true),
          ),
          _ScheduleOption(
            label: 'Schedule for later',
            desc: 'Pick a date and time',
            active: !isNow,
            onTap: () => onNowChanged(false),
          ),
          if (!isNow) ...[
            const SizedBox(height: 24),
            DatePickerRow(
              selectedDate: scheduledDate ?? DateTime.now(),
              onDateSelected: onDateChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleOption extends StatelessWidget {
  const _ScheduleOption({
    required this.label,
    required this.desc,
    required this.active,
    required this.onTap,
  });
  final String label;
  final String desc;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBR,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withAlpha(15) : Colors.white,
            borderRadius: AppRadius.mdBR,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium),
                    Text(desc, style: AppTextStyles.meta),
                  ],
                ),
              ),
              // Custom Radio-like indicator (avoiding deprecated API)
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: active ? AppColors.primary : AppColors.border, width: active ? 6 : 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5: Address
// ─────────────────────────────────────────────────────────────────────────────

class StepAddress extends StatelessWidget {
  const StepAddress({
    super.key,
    required this.addressCtrl,
    required this.notesCtrl,
    required this.onLocate,
    required this.locating,
  });
  final TextEditingController addressCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback onLocate;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup Address', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          AppTextField(
            controller: addressCtrl,
            label: 'Street Address',
            hint: 'Enter your address',
            suffix: IconButton(
              onPressed: onLocate,
              icon: locating 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(PhosphorIconsRegular.crosshair, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: notesCtrl,
            label: 'Pickup Notes',
            hint: 'e.g. Near the blue gate, knock hard',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6: Review (Receipt-like)
// ─────────────────────────────────────────────────────────────────────────────

class StepReview extends StatelessWidget {
  const StepReview({
    super.key,
    required this.category,
    required this.binSize,
    required this.extraBags,
    required this.address,
    required this.isNow,
    required this.total,
  });
  final String category;
  final String binSize;
  final int extraBags;
  final String address;
  final bool isNow;
  final double total;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Order', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBR,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Category', value: category),
                _SummaryRow(label: 'Bin Size', value: binSize),
                _SummaryRow(label: 'Extra Bags', value: '$extraBags'),
                _SummaryRow(label: 'Pickup', value: isNow ? 'ASAP' : 'Scheduled'),
                _SummaryRow(label: 'Service Fee', value: Fmt.currency(2.0)),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: AppTextStyles.bodyMedium),
                    Text(Fmt.currency(total + 2.0), style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text('Payment will be collected in cash upon arrival.', style: AppTextStyles.meta)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.meta),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
