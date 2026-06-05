import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Single notification list card — Rydr's notificationCard pattern.
///
/// Rydr bugs fixed:
///  - Bare function, not a StatelessWidget → proper widget class
///  - Hardcoded 65px height → flexible height for long body text
///  - Hardcoded rydrlogo image → Phosphor icon keyed from notification type
///  - No real data binding → reads title/body/createdAt from notification map
///  - No const constructor → fixed
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
    final title    = notification['title'] as String? ?? 'Notification';
    final body     = notification['body']  as String? ?? '';
    final isRead   = notification['isRead'] as bool? ?? false;
    final typeStr  = notification['type']  as String? ?? '';
    final created  = DateTime.tryParse(notification['createdAt'] as String? ?? '');
    final timeStr  = created != null ? Fmt.relativeTime(created) : '';
    final icon     = _iconForType(typeStr);
    final iconColor = _colorForType(typeStr);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          // Unread → slightly elevated card; read → muted
          color: isRead ? AppColors.card : AppColors.cardElevated,
          borderRadius: AppRadius.mdBR,
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.borderActive.withAlpha(60),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container (Rydr: rydrlogo image → BinLink: Phosphor icon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: AppRadius.smBR,
                border: Border.all(color: iconColor.withAlpha(60)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Text content — flexible height (Rydr bug: 65px fixed → overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(timeStr, style: AppTextStyles.chip),
                      ],
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Unread indicator dot
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.steelBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
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

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOKING_UPDATE':
      case 'BOOKING':
      case 'PICKUP':
        return AppColors.steelBlue;
      case 'JOB_UPDATE':
      case 'NEW_JOB':
      case 'COLLECTOR':
        return AppColors.warning;
      case 'EARNINGS':
      case 'PAYOUT':
      case 'PAYMENT':
      case 'SUBSCRIPTION':
        return AppColors.success;
      case 'SYSTEM':
        return AppColors.skyBlue;
      default:
        return AppColors.muted;
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
