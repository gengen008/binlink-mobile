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
    {'id': 'Household', 'icon': AppAssets.bin3d},
    {'id': 'Recycling', 'icon': AppAssets.recycleBin},
    {'id': 'Organic',   'icon': AppAssets.leaf},
  ];

  final _sizes = [
    {'id': 'SMALL',  'label': 'Standard Bin', 'price': 30, 'icon': AppAssets.bin3d, 'desc': 'Best for daily home waste'},
    {'id': 'MEDIUM', 'label': 'Family Bin',   'price': 40, 'icon': AppAssets.bin3d, 'desc': 'Ideal for large families'},
    {'id': 'LARGE',  'label': 'Industrial',   'price': 50, 'icon': AppAssets.truck3d, 'desc': 'Bulk/Construction load'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Service', style: AppTextStyles.h2),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Category Horizontal Scroll ──
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final c = _categories[i];
                final isSelected = _selectedCategory == c['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = c['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(c['icon']!, width: 32, height: 32),
                        const SizedBox(height: 8),
                        Text(c['id']!, style: AppTextStyles.label.copyWith(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),

          // ── Size List ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: _sizes.map((s) {
                final isSelected = _selectedSize == s['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = s['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Image.asset(s['icon'] as String, width: 48, height: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['label'] as String, style: AppTextStyles.h4),
                              Text(s['desc'] as String, style: AppTextStyles.label),
                            ],
                          ),
                        ),
                        Text('GHS ${s['price']}', style: AppTextStyles.mono.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Extra Bags ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Extra Bags", style: AppTextStyles.h4),
                    Text("GHS 6.00 per bag", style: AppTextStyles.label),
                  ],
                ),
                const Spacer(),
                _CounterBtn(icon: Icons.remove, onTap: () => setState(() { if(_extraBags > 0) _extraBags--; })),
                const SizedBox(width: 16),
                Text("$_extraBags", style: AppTextStyles.h3),
                const SizedBox(width: 16),
                _CounterBtn(icon: Icons.add, isPrimary: true, onTap: () => setState(() => _extraBags++)),
              ],
            ),
          ),

          // ── CTA ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: AppButton(
              label: 'Confirm $_selectedCategory',
              onPressed: () => widget.onServiceSelected(_selectedCategory, _selectedSize, _extraBags),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  const _CounterBtn({required this.icon, required this.onTap, this.isPrimary = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isPrimary ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}
