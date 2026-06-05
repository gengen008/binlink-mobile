// Rydr authHeader(BuildContext context) — literal transplant.
//
// Rydr source: views/Authentication/components/auth_header.dart
//   FadeInDown(1500ms) > Column([
//     Center(Container(w:105, h:33, image(logo))),
//     YMargin(30),
//     Container(screenWidth, 160, image(authimage1))
//   ])
//
// BinLink replacements only:
//   - logo image → BL icon + BinLink wordmark (same 105×33 dimensions)
//   - authimage1 → Row(spaceEvenly, [_EcoItem × 4]) in same 160px container

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

Widget authHeader(BuildContext context) {
  return FadeInDown(
    duration: const Duration(milliseconds: 1500),
    child: Column(
      children: [
        // Rydr: Center(Container(w:105, h:33, alignment:center, DecorationImage(logo)))
        // BinLink: same dimensions, BL icon + BinLink text
        Center(
          child: SizedBox(
            width: 105,
            height: 33,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'BL',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Rydr: YMargin(30)
        const SizedBox(height: 30),
        // Rydr: Container(w:screenWidth, h:160, DecorationImage(authimage1))
        // BinLink: same container, eco category cards
        Container(
          width: MediaQuery.sizeOf(context).width,
          height: 160,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EcoItem(
                icon: PhosphorIconsFill.trashSimple,
                label: 'Household',
                time: '30 GHC',
                color: AppColors.steelBlue,
              ),
              _EcoItem(
                icon: PhosphorIconsFill.recycle,
                label: 'Plastic',
                time: '30 GHC',
                color: AppColors.success,
              ),
              _EcoItem(
                icon: PhosphorIconsFill.leaf,
                label: 'Organic',
                time: '40 GHC',
                color: Color(0xFF34D399),
              ),
              _EcoItem(
                icon: PhosphorIconsFill.laptop,
                label: 'E-Waste',
                time: '50 GHC',
                color: Color(0xFFA78BFA),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Rydr FavoriteItems card — exact structure (h:120, w:110, border:PrimaryColor, br:all(25))
class _EcoItem extends StatelessWidget {
  const _EcoItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String   label;
  final String   time;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    // Rydr: ClipRect > Container(h:120, w:110, border:PrimaryColor, br:all(25))
    //   > Column[YMargin(10), Container(67×67, circle, Color(0xFFF5F6F5)),
    //            YMargin(5), Text(10,w600,Primarydark), YMargin(5), Text(9,w400,#999393)]
    return ClipRect(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        height: 120,
        width: 110,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.steelBlue),
          borderRadius: const BorderRadius.all(Radius.circular(25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rydr: YMargin(10)
            const SizedBox(height: 10),
            // Rydr: Container(67×67, circle, Color(0xFFF5F6F5), Padding(18, SvgPicture(icon, 26×26)))
            Container(
              height: 67,
              width: 67,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF5F6F5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            // Rydr: YMargin(5)
            const SizedBox(height: 5),
            // Rydr: Text(text, montserrat, 10, w600, Primarydark)
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.midnightNavy,
              ),
            ),
            // Rydr: YMargin(5)
            const SizedBox(height: 5),
            // Rydr: Text(time, montserrat, 9, w400, #999393)
            Text(
              time,
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF999393),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
