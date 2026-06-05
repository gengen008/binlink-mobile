// Rydr notificationCard() — exact transplant.
// Rydr source: notifications.dart notificationCard()
//   Padding(h:20,v:5) > Container(p:h10,v5, h:65, w:sw, br:15, Primaryfield) > Row([
//     Padding(all:7, Image(rydrlogo)),
//     Column(center, start, [Text(title,10,w600), SizedBox(5), Text(body,7,w300)])
//   ])

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/rydr_assets.dart';
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
    final title = notification['title'] as String? ?? 'Notification';
    final body  = notification['body']  as String? ?? '';

    // Rydr exact: Padding(h:20,v:5) > Container(p:h10,v5, h:65, w:sw, br:15, Primaryfield)
    //   > Row([Padding(all:7, Image(rydrlogo)), Column([title, YMargin(5), body])])
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.0),
          height: 65,
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: const Color(0xFFDCE1DE),
          ),
          child: Row(
            children: [
              // Rydr: Padding(all:7, Image(rydrlogo))
              Padding(
                padding: const EdgeInsets.all(7.0),
                child: Image.asset(RydrAssets.rydrlogo),
              ),
              // Rydr: Column(center, start, [title, YMargin(5), body])
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2421),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: GoogleFonts.montserrat(
                        fontSize: 7.0,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF1F2421),
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
              color: const Color(0xFFF3F3C1),
              fontSize: 9,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}
