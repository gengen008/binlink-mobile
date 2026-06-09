import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar.dart';
import 'active_pickup_screen.dart';

class PickupsScreen extends StatefulWidget {
  const PickupsScreen({super.key});

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectorProvider>().loadJobs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectorProvider>();

    return Scaffold(
      appBar: AppScaffoldBar(
        title: 'My Pickups',
        showBack: false,
        trailing: IconButton(
          onPressed: () => prov.loadJobs(),
          icon: prov.loadingJobs 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(LucideIcons.refreshCw),
        ),
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.bodyMedium,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Scheduled'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _JobTabList(
                  jobs: prov.assignedJobs,
                  emptyLabel: 'No active pickups',
                  onRefresh: prov.loadJobs,
                ),
                _JobTabList(
                  jobs: prov.pendingJobs,
                  emptyLabel: 'No scheduled pickups',
                  onRefresh: prov.loadJobs,
                ),
                _JobTabList(
                  jobs: prov.completedJobs,
                  emptyLabel: 'No completed pickups',
                  onRefresh: prov.loadJobs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTabList extends StatelessWidget {
  const _JobTabList({required this.jobs, required this.emptyLabel, required this.onRefresh});
  final List<Map<String, dynamic>> jobs;
  final String emptyLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.emptyPickups, height: 80),
            const SizedBox(height: 16),
            Text(emptyLabel, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: jobs.length,
        itemBuilder: (context, i) => _CollectorJobCard(job: jobs[i]),
      ),
    );
  }
}

class _CollectorJobCard extends StatelessWidget {
  const _CollectorJobCard({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String? ?? '';
    final address = job['pickupAddress'] as String? ?? '—';
    final amount = Fmt.toDouble(job['totalAmount']) * 0.9; // 90% share
    final date = job['createdAt'] as String?;
    final isActive = ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () {
          if (isActive) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ActivePickupScreen(booking: job)));
          }
        },
        borderRadius: AppRadius.mdBR,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.mdBR,
            border: Border.all(color: isActive ? AppColors.primary.withAlpha(100) : AppColors.border, width: isActive ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(address, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 12),
                  Text(Fmt.currency(amount), style: AppTextStyles.mono.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoBit(icon: LucideIcons.calendar, label: date != null ? Fmt.shortDate(date) : 'Today'),
                  const SizedBox(width: 16),
                  _InfoBit(icon: LucideIcons.trash2, label: Fmt.categoryLabel(job['wasteCategory'] as String? ?? '')),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('ACTIVE', style: AppTextStyles.small.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
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

class _InfoBit extends StatelessWidget {
  const _InfoBit({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
