import 'package:flutter/material.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Logo + brand block for white/light auth screens.
Widget authHeader(BuildContext context) {
  return Center(
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'BinLink',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Eco Waste Collection',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );
}
