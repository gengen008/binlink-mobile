import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
