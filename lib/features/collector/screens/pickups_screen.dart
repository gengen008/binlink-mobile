import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
      child: Column(
        children: [
          // ── Branded jobs banner ────────────────────────────────────
          Consumer<CollectorProvider>(
            builder: (_, prov, __) => _JobsBanner(
              assignedCount:  prov.assignedJobs.length,
              pendingCount:   prov.pendingJobs.length,
              completedCount: prov.completedJobs.length,
              loading:        prov.loadingJobs,
              onRefresh:      () => context.read<CollectorProvider>().loadJobs(),
            ),
          ),

          const SizedBox(height: 12),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.lgBR,
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.mdBR,
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
    );
  }
}

// ── Jobs banner ───────────────────────────────────────────────────────────────

class _JobsBanner extends StatelessWidget {
  const _JobsBanner({
    required this.assignedCount,
    required this.pendingCount,
    required this.completedCount,
    required this.loading,
    required this.onRefresh,
  });
  final int assignedCount;
  final int pendingCount;
  final int completedCount;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF052659), Color(0xFF0A2D5A)],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.steelBlue.withAlpha(18),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Pickups', style: AppTextStyles.h2),
                          Text('Active jobs & history',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.skyBlue)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRefresh,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.steelBlue.withAlpha(25),
                            borderRadius: AppRadius.smBR,
                            border: Border.all(
                                color: AppColors.steelBlue.withAlpha(60)),
                          ),
                          child: loading
                              ? const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.steelBlue),
                                )
                              : const Icon(PhosphorIconsRegular.arrowClockwise,
                                  color: AppColors.steelBlue, size: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stats chips
                  Row(
                    children: [
                      _StatChip(
                        label: 'Active',
                        count: assignedCount,
                        icon: PhosphorIconsFill.truck,
                        color: AppColors.steelBlue,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Pending',
                        count: pendingCount,
                        icon: PhosphorIconsFill.clock,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Done',
                        count: completedCount,
                        icon: PhosphorIconsFill.checkCircle,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text('$count',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: color, fontSize: 13)),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color.withAlpha(200), fontSize: 10)),
        ],
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

    // Rydr: date badge row above list + FadeInUp(2000ms) on ListView
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateLabel = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.deepOcean,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                dateLabel,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: FadeInUp(
            duration: const Duration(milliseconds: 2000),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _JobCard(job: jobs[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Job card — LITERAL Rydr tripCard() transplant ────────────────────────────
//
// Rydr source: trip_screen.dart tripCard()
//   Padding(h:20,v:5) > Container(p:h15,v5, h:65, w:sw, br:15, Primaryfield)
//   > Row(spaceBetween, crossStart, [
//       Row[Padding(all:7, Image(rydrlogo)), Column(center,start,[addr,YMargin(5),date])],
//       Column(center, end, [price, YMargin(5), "Trip Completed"])
//     ]).ripple(() { Navigator.push(context, TripHistory()); })

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final status   = job['status'] as String? ?? '';
    final address  = job['pickupAddress'] as String? ?? '';
    final amount   = Fmt.toDouble(job['totalAmount']);
    final date     = job['createdAt'] as String?;
    final isActive = ['ACCEPTED', 'EN_ROUTE', 'ARRIVED'].contains(status);

    // Rydr: Padding(horizontal:20, vertical:5)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
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
          // Rydr: padding:h15,v5 — height:65 — w:screenWidth — br:15 — Primaryfield — NO border
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5.0),
          height: 65,
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: AppColors.fieldFill,
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
                      // Rydr: Text(address, montserrat, 10, w600, Primarydark)
                      Text(
                        address,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      // Rydr: Text(date, montserrat, 7, w300, Primarydark)
                      Text(
                        date != null ? Fmt.shortDate(date) : '',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 7,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textBody,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Rydr: Text("Trip Completed", montserrat, 7, w300, Primarydark)
                  Text(
                    Fmt.statusLabel(status),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 7,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textBody,
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

  void _showDetail(BuildContext ctx) {
    final status  = job['status'] as String? ?? '';
    final binSize = job['binSize'] as String? ?? '';
    final address = job['pickupAddress'] as String? ?? '';
    final amount  = Fmt.toDouble(job['totalAmount']);
    final hhName  = (job['household'] as Map?)?['fullName'] as String? ??
        'Household';
    final date    = job['createdAt'] as String?;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.deepOcean,
          borderRadius: AppRadius.sheetBR,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: AppRadius.fullBR)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Pickup Details', style: AppTextStyles.h3),
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
              const Text('Earnings', style: AppTextStyles.h4),
              Text(Fmt.currency(amount * 0.9),
                  style: AppTextStyles.monoLg.copyWith(color: AppColors.iceBlue)),
            ]),
          ],
        ),
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
