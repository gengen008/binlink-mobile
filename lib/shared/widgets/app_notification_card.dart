// Rydr notificationCard() — literal transplant.
//
// Rydr source: notifications.dart notificationCard()
//   Padding(h:20,v:5) > Container(p:h10,v5, h:65, w:screenWidth, br:15,
//     Primaryfield, NO border) > Row([
//       Padding(all:7, Image(rydrlogo)),
//       Column(center, start, [Text(title,10,w600,Primarydark), YMargin(5), Text(body,7,w300,Primarydark)])
//     ])
//
// BinLink replacements only:
//   - rydrlogo image → Phosphor icon keyed from notification type (same Padding(all:7) wrapper, no circle)
//   - Primaryfield → AppColors.fieldFill
//   - Primarydark → AppColors.textPrimary / AppColors.textBody
//   - real API data (title, body from notification map)
//
// NOTE: Rydr has NO circle icon container, NO border, NO Expanded on Column, NO unread dot.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Single notification list card — LITERAL Rydr notificationCard() transplant.
///
/// [notification] — map from GET /api/notifications response:
///   { id, title, body, type, isRead, createdAt }
class AppNotificationCard extends StatelessWidget {
  const AppNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title     = notification['title'] as String? ?? 'Notification';
    final body      = notification['body']  as String? ?? '';
    final typeStr   = notification['type']  as String? ?? '';
    final icon      = _iconForType(typeStr);

    // Rydr: Padding(horizontal:20, vertical:5)
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
          // Rydr: padding:h10,v5 — height:65 — w:screenWidth — br:15 — Primaryfield — NO border
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          height: 65,
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.fieldFill,
          ),
          child: Row(
            children: [
              // Rydr: Padding(all:7, Image(rydrlogo)) → plain icon, no circle container
              Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(icon, color: AppColors.steelBlue, size: 16),
              ),
              // Rydr: Column(mainAxisAlignment:center, crossAxisAlignment:start, [...])
              // NOTE: NOT Expanded in Rydr
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rydr: Text(title, montserrat, 10, w600, Primarydark)
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    // Rydr: Text(body, montserrat, 7, w300, Primarydark)
                    Text(
                      body,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 7,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOKING_UPDATE':
      case 'BOOKING':
      case 'PICKUP':
        return PhosphorIconsFill.trashSimple;
      case 'JOB_UPDATE':
      case 'NEW_JOB':
      case 'COLLECTOR':
        return PhosphorIconsFill.truck;
      case 'EARNINGS':
      case 'PAYOUT':
      case 'PAYMENT':
      case 'SUBSCRIPTION':
        return PhosphorIconsFill.wallet;
      case 'SYSTEM':
        return PhosphorIconsFill.bell;
      default:
        return PhosphorIconsFill.bellSimple;
    }
  }
}

// ── Date section header — Rydr's date chip pattern ────────────────────────────

/// "10th January 2022" style chip at the top of a notifications date group.
class NotificationDateChip extends StatelessWidget {
  const NotificationDateChip({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Rydr: Container(width:90, height:30, borderRadius:5, color:Primarydark) centered date label
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        width: 90,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.midnightNavy,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            Fmt.date(date),
            style: AppTextStyles.chip.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}
