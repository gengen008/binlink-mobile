import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';

class CollectorNotificationsScreen extends StatefulWidget {
  const CollectorNotificationsScreen({super.key});

  @override
  State<CollectorNotificationsScreen> createState() =>
      _CollectorNotificationsScreenState();
}

class _CollectorNotificationsScreenState
    extends State<CollectorNotificationsScreen> {
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
          _notifs = List<Map<String, dynamic>>.from(
              res.data['data'] as List? ?? []);
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

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'NEW_JOB':     return PhosphorIconsFill.trashSimple;
      case 'JOB_UPDATE':  return PhosphorIconsFill.arrowCircleRight;
      case 'EARNINGS':    return PhosphorIconsFill.wallet;
      case 'PAYOUT':      return PhosphorIconsFill.bank;
      case 'SYSTEM':      return PhosphorIconsFill.info;
      default:            return PhosphorIconsFill.bell;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'NEW_JOB':    return AppColors.warning;
      case 'JOB_UPDATE': return AppColors.steelBlue;
      case 'EARNINGS':   return AppColors.success;
      case 'PAYOUT':     return AppColors.success;
      case 'SYSTEM':     return AppColors.skyBlue;
      default:           return AppColors.muted;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt   = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.white),
                    ),
                    const Expanded(
                      child: Text('Notifications', style: AppTextStyles.h3),
                    ),
                  ],
                ),
              ),

              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.warning, strokeWidth: 2,
                    ),
                  ),
                )
              else if (_notifs.isEmpty)
                Expanded(
                  child: Center(
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
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.textSecondary,
                            )),
                        const SizedBox(height: 6),
                        const Text('Go online to start receiving job alerts.',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n      = _notifs[i];
                      final isRead = n['isRead'] as bool? ?? false;
                      final type   = n['type'] as String?;
                      final color  = _typeColor(type);

                      return GestureDetector(
                        onTap: isRead
                            ? null
                            : () => _markRead(n['id'] as String, i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.card
                                : color.withAlpha(15),
                            borderRadius: AppRadius.xlBR,
                            border: Border.all(
                              color: isRead
                                  ? AppColors.border
                                  : color.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: AppRadius.mdBR,
                                ),
                                child: Icon(_typeIcon(type),
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['title'] as String? ?? '',
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ),
                                        Text(
                                          _timeAgo(n['createdAt'] as String?),
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['body'] as String? ?? '',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
