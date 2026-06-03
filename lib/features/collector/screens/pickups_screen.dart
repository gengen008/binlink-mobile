import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';
import 'active_pickup_screen.dart';

class PickupsScreen extends StatefulWidget {
  const PickupsScreen({super.key});

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectorProvider>().loadJobs();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Pickups', style: AppTextStyles.h2),
                      Text('Manage your jobs',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  const Spacer(),
                  Consumer<CollectorProvider>(
                    builder: (_, prov, __) => prov.loadingJobs
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.steelBlue,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => context.read<CollectorProvider>().loadJobs(),
                            child: const Icon(
                              PhosphorIconsRegular.arrowClockwise,
                              color: AppColors.skyBlue,
                              size: 22,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.muted,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Assigned'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Consumer<CollectorProvider>(
                builder: (_, prov, __) => TabBarView(
                  controller: _tab,
                  children: [
                    _JobList(
                      jobs: prov.assignedJobs,
                      emptyIcon: PhosphorIconsRegular.truck,
                      emptyTitle: 'No assigned pickups',
                      emptySubtitle: 'Accept a request from the map to get started',
                    ),
                    _JobList(
                      jobs: prov.pendingJobs,
                      emptyIcon: PhosphorIconsRegular.clock,
                      emptyTitle: 'No pending pickups',
                      emptySubtitle: 'Scheduled future pickups will appear here',
                    ),
                    _JobList(
                      jobs: prov.completedJobs,
                      emptyIcon: PhosphorIconsRegular.checkCircle,
                      emptyTitle: 'No completed pickups',
                      emptySubtitle: 'Your finished jobs will appear here',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });
  final List<Map<String, dynamic>> jobs;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(emptyIcon, color: AppColors.muted, size: 28),
              ),
              const SizedBox(height: 16),
              Text(emptyTitle,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: 6),
              Text(emptySubtitle,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _JobCard(job: jobs[i]),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final status   = job['status'] as String? ?? '';
    final binSize  = job['binSize'] as String? ?? '';
    final address  = job['pickupAddress'] as String? ?? '';
    final amount   = (job['totalAmount'] as num?)?.toDouble() ?? 0;
    final category = job['wasteCategory'] as String?;
    final date     = job['createdAt'] as String?;
    final prov     = context.read<CollectorProvider>();
    final isActive = ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(status);

    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.push(context,
              MaterialPageRoute(
                builder: (_) => ActivePickupScreen(booking: job),
              ));
        } else {
          _showDetail(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.steelBlue.withAlpha(15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppColors.steelBlue.withAlpha(80)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + amount
            Row(
              children: [
                StatusBadge(status: status),
                const Spacer(),
                Text(Fmt.currency(amount),
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.iceBlue,
                    )),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsRegular.mapPin,
                    color: AppColors.muted, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(address,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips row
            Row(
              children: [
                _Chip(
                  icon: PhosphorIconsRegular.trashSimple,
                  label: Fmt.binSizeLabel(binSize).split(' ').first,
                ),
                if (category != null) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    icon: PhosphorIconsRegular.recycle,
                    label: category.replaceAll('_', ' '),
                  ),
                ],
                const Spacer(),
                if (date != null)
                  Text(Fmt.shortDate(date),
                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),

            if (isActive) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsRegular.arrowRight,
                        color: AppColors.white, size: 14),
                    const SizedBox(width: 6),
                    Text('Continue Pickup',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext ctx) {
    final status  = job['status'] as String? ?? '';
    final binSize = job['binSize'] as String? ?? '';
    final address = job['pickupAddress'] as String? ?? '';
    final amount  = (job['totalAmount'] as num?)?.toDouble() ?? 0;
    final hhName  = (job['household'] as Map?)?['fullName'] as String? ??
        'Household';
    final date    = job['createdAt'] as String?;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.deepOcean,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Pickup Details', style: AppTextStyles.h3),
                const Spacer(),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 16),
            _DetailTile(icon: PhosphorIconsRegular.user, label: 'Household', value: hhName),
            _DetailTile(icon: PhosphorIconsRegular.mapPin, label: 'Address', value: address),
            _DetailTile(icon: PhosphorIconsRegular.trashSimple, label: 'Bin', value: Fmt.binSizeLabel(binSize)),
            if (date != null)
              _DetailTile(icon: PhosphorIconsRegular.calendarBlank, label: 'Date', value: Fmt.shortDate(date)),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Earnings', style: AppTextStyles.h4),
              Text(Fmt.currency(amount * 0.8),
                  style: AppTextStyles.monoLg.copyWith(color: AppColors.iceBlue)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border.withAlpha(60),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.muted, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10, color: AppColors.muted,
              )),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
