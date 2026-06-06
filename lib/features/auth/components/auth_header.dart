import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

Widget authHeader(BuildContext context) {
  return Center(
    child: Column(
      children: [
        SvgPicture.asset(AppAssets.logoSvg, width: 80, height: 80),
        const SizedBox(height: 16),
        Text(
          'BinLink',
          style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
        ),
      ],
    ),
  );
}
