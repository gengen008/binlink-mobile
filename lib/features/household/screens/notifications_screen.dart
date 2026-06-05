import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_bar.dart';
import '../../../shared/widgets/app_notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/api/notifications');
      if (mounted) {
        setState(() {
          _notifs = List<Map<String, dynamic>>.from(res.data['data'] as List? ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id, int idx) async {
    try {
      await ApiClient.patch('/api/notifications/$id/read', {});
      if (mounted) {
        setState(() => _notifs[idx] = {..._notifs[idx], 'isRead': true});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: const AppScaffoldBar(title: 'Notifications'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.steelBlue, strokeWidth: 2,
                ),
              )
            : _notifs.isEmpty
                ? _EmptyState()
                : _NotifList(
                    notifs: _notifs,
                    onMarkRead: _markRead,
                  ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(PhosphorIconsRegular.bell,
                color: AppColors.muted, size: 32),
          ),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          const Text("You're all caught up!", style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Notification list with date chips (Rydr pattern) ─────────────────────────

class _NotifList extends StatelessWidget {
  const _NotifList({required this.notifs, required this.onMarkRead});
  final List<Map<String, dynamic>> notifs;
  final Future<void> Function(String id, int idx) onMarkRead;

  /// Groups notifications by date so we can insert NotificationDateChip headers.
  List<_NotifRow> _buildRows() {
    final rows = <_NotifRow>[];
    String? lastDateKey;

    for (var i = 0; i < notifs.length; i++) {
      final n = notifs[i];
      final createdStr = n['createdAt'] as String?;
      final dt = createdStr != null ? DateTime.tryParse(createdStr) : null;

      if (dt != null) {
        final dateKey = '${dt.year}-${dt.month}-${dt.day}';
        if (dateKey != lastDateKey) {
          rows.add(_NotifRow.dateChip(dt));
          lastDateKey = dateKey;
        }
      }

      rows.add(_NotifRow.card(n, i));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        if (row.isDateChip) {
          return NotificationDateChip(date: row.date!);
        }
        final n = row.notif!;
        final isRead = n['isRead'] as bool? ?? false;
        return AppNotificationCard(
          notification: n,
          onTap: isRead ? null : () => onMarkRead(n['id'] as String, row.idx!),
        );
      },
    );
  }
}

class _NotifRow {
  final bool isDateChip;
  final DateTime? date;
  final Map<String, dynamic>? notif;
  final int? idx;

  const _NotifRow._({required this.isDateChip, this.date, this.notif, this.idx});

  factory _NotifRow.dateChip(DateTime d) =>
      _NotifRow._(isDateChip: true, date: d);

  factory _NotifRow.card(Map<String, dynamic> n, int i) =>
      _NotifRow._(isDateChip: false, notif: n, idx: i);
}
