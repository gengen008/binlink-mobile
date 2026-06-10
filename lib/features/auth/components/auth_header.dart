import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

Widget authHeader(BuildContext context) {
  return Center(
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(PhosphorIcons.leaf(PhosphorIconsStyle.fill), color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'BinLink',
          style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
        ),
      ],
    ),
  );
}
