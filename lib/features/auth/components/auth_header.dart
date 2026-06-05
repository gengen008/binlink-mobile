// Trippo-style auth header — eco branding for dark auth scaffolds.
//
// Replaces the old Rydr authimage1 illustration with a minimal logo + name
// block that works on the dark #0F172A + main.jpg overlay background.

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/rydr_assets.dart';

Widget authHeader(BuildContext context) {
  return FadeIn(
    duration: const Duration(milliseconds: 1000),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset(RydrAssets.logo, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BinLink',
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Eco Waste Collection',
            style: AppTextStyles.caption.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    ),
  );
}
