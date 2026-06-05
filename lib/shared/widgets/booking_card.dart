// Rydr tripCard() — literal transplant.
//
// Rydr source: trip_screen.dart tripCard()
//   Padding(h:20,v:5) > Container(p:h15,v5, h:65, w:sw, br:15, Primaryfield, NO border)
//   > Row(spaceBetween, crossStart, [
//       Row[Padding(all:7, Image(rydrlogo)), Column(center,start,[addr,YMargin(5),date])],
//       Column(center, end, [price, YMargin(5), "Trip Completed"])
//     ]).ripple(() { Navigator.push(context, TripHistory()); })
//
// BinLink replacements only:
//   - rydrlogo image → Phosphor trashSimple icon (same Padding(all:7) wrapper, no circle)
//   - Primaryfield → AppColors.fieldFill
//   - "Trip Completed" → Fmt.statusLabel(status)
//   - addr/date from booking map
//   - Primarydark → AppColors.textPrimary / AppColors.textBody
//
// NOTE: Rydr has NO circle icon container, NO border.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showCollector = false,
  });

  final Map<String, dynamic> booking;
  final VoidCallback? onTap;
  final bool showCollector;

  @override
  Widget build(BuildContext context) {
    final status    = booking['status'] as String? ?? 'PENDING';
    final address   = booking['pickupAddress'] as String? ?? '';
    final amount    = Fmt.toDouble(booking['totalAmount']);
    final createdAt = booking['createdAt'] as String?;

    // Rydr: Padding(horizontal:20, vertical:5)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Rydr: padding:h15,v5 — height:65 — w:screenWidth — br:15 — Primaryfield — NO border
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5.0),
          height: 65,
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: const Color(0xFFDCE1DE),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rydr: Row[Padding(all:7, Image(rydrlogo)), Column[addr, YMargin(5), date]]
              Row(
                children: [
                  // Rydr: Padding(all:7, Image(rydrlogo)) → plain icon, no circle container
                  const Padding(
                    padding: EdgeInsets.all(7.0),
                    child: Icon(PhosphorIconsFill.trashSimple,
                        color: AppColors.steelBlue, size: 15),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rydr: Text(location, montserrat, 10, w600, Primarydark)
                      Text(
                        address,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.midnightNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      // Rydr: Text(date, montserrat, 7, w300, Primarydark)
                      Text(
                        createdAt != null ? Fmt.shortDate(createdAt) : '',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 7,
                          fontWeight: FontWeight.w300,
                          color: AppColors.midnightNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Rydr: Column(center, end, [price, YMargin(5), "Trip Completed"])
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Rydr: Text(price, montserrat, 10, w600, Primarydark)
                  Text(
                    Fmt.currency(amount),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Rydr: Text("Trip Completed", montserrat, 7, w300, Primarydark)
                  Text(
                    Fmt.statusLabel(status),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 7,
                      fontWeight: FontWeight.w300,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
