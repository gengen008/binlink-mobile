import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_assets.dart';
import '../../../shared/widgets/app_button.dart';

class ServiceSelectionSheet extends StatefulWidget {
  const ServiceSelectionSheet({
    super.key,
    required this.onServiceSelected,
    required this.onCancel,
  });

  final Function(String category, String binSize, int extraBags) onServiceSelected;
  final VoidCallback onCancel;

  @override
  State<ServiceSelectionSheet> createState() => _ServiceSelectionSheetState();
}

class _ServiceSelectionSheetState extends State<ServiceSelectionSheet> {
  String _selectedCategory = 'Household';
  String _selectedSize = 'SMALL';
  int _extraBags = 0;

  final _categories = [
    {'id': 'Household', 'icon': AppAssets.trashBin},
    {'id': 'Recycling', 'icon': AppAssets.recycleBin},
    {'id': 'Organic',   'icon': AppAssets.leaf},
  ];

  final _sizes = [
    {'id': 'SMALL',  'label': 'Small Bin',  'price': 30, 'icon': AppAssets.trashBin, 'desc': '1-2 standard bags'},
    {'id': 'MEDIUM', 'label': 'Medium Bin', 'price': 40, 'icon': AppAssets.trashBin, 'desc': '3-4 standard bags'},
    {'id': 'LARGE',  'label': 'Large Bin',  'price': 50, 'icon': AppAssets.trashBin, 'desc': '5+ standard bags'},
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Choose a pickup', style: AppTextStyles.h2),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onCancel,
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Selection
                    Text('Waste Type', style: AppTextStyles.section),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _categories.map((c) {
                        final isSelected = _selectedCategory == c['id'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCategory = c['id']!),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Image.asset(c['icon']!, width: 32, height: 32, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  Text(c['id']!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Bin Size Selection (Uber-style list)
                    Text('Bin Size', style: AppTextStyles.section),
                    const SizedBox(height: 8),
                    ..._sizes.map((s) {
                      final isSelected = _selectedSize == s['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = s['id'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 8)] : [],
                          ),
                          child: Row(
                            children: [
                              Image.asset(s['icon'] as String, width: 40, height: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['label'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                                    Text(s['desc'] as String, style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              Text('GHS ${s['price']}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // ── Extra Bags Counter ──────────────────────────────────
                    Text('Extra Bags', style: AppTextStyles.section),
                    const SizedBox(height: 4),
                    Text('GHS 6 each — add if you have overflow bags', style: AppTextStyles.caption),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() { if (_extraBags > 0) _extraBags--; }),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.remove, size: 20),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text('$_extraBags', style: AppTextStyles.h2),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setState(() => _extraBags++),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Icon(Icons.add, size: 20, color: AppColors.primary),
                          ),
                        ),
                        const Spacer(),
                        if (_extraBags > 0)
                          Text(
                            '+ GHS ${_extraBags * 6}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Action
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: AppButton(
                  label: 'Confirm $_selectedCategory Pickup',
                  onPressed: () => widget.onServiceSelected(_selectedCategory, _selectedSize, _extraBags),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
