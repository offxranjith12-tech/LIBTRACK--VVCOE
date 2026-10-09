import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_helper.dart';
import '../../widgets/shared_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(currentStaffProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.read).length,
      orElse: () => 0,
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    // On desktop/tablet, constrain content and use wider grids
    final isWide = screenWidth >= 600;
    final isDesktop = screenWidth >= 900;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(currentStaffProvider);
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(notificationsProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 20,
                12,
                isWide ? 28 : 20,
                24,
              ),
              children: [
                // ── Header row ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LibTrack',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                )),
                        Text('VV College of Engineering',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textMuted)),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () =>
                              ref.read(staffNavIndexProvider.notifier).state =
                                  3,
                          icon: const Icon(Icons.notifications_outlined),
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              shape: const CircleBorder()),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text('$unread',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Profile card ─────────────────────────────────────────────
                staffAsync.when(
                  data: (staff) => Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => openPhotoViewer(context,
                              name: staff.name,
                              image: decodeAvatar(staff.photoUrl)),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            backgroundImage: decodeAvatar(staff.photoUrl),
                            child: (decodeAvatar(staff.photoUrl) == null)
                                ? Text(
                                    staff.name
                                        .trim()
                                        .split(' ')
                                        .where((e) => e.isNotEmpty)
                                        .map((e) => e[0])
                                        .take(2)
                                        .join(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staff.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17)),
                              const SizedBox(height: 3),
                              Text(
                                '${staff.designation} • ${staff.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12.5),
                              ),
                              const SizedBox(height: 2),
                              Text(staff.department,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const _CardSkeleton(height: 100),
                  error: (e, _) =>
                      _ErrorCard(message: 'Could not load profile: $e'),
                ),
                const SizedBox(height: 22),

                // ── Overview stats grid ───────────────────────────────────────
                const SectionHeader(title: 'Overview'),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => GridView.count(
                    // 2 cols on mobile, 4 cols on desktop/tablet
                    crossAxisCount: isDesktop ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: isDesktop ? 1.1 : 1.3,
                    children: [
                      _OverviewCard(
                          icon: Icons.assignment_turned_in_rounded,
                          value: '${stats.borrowedBooks}',
                          label: 'Borrowed Books Count',
                          color: AppColors.primary),
                      _OverviewCard(
                          icon: Icons.assignment_return_rounded,
                          value: '${stats.returnedBooks}',
                          label: 'Returned Books',
                          color: AppColors.success),
                      _OverviewCard(
                          icon: Icons.alarm_on_rounded,
                          value: '${stats.dueSoon}',
                          label: 'Due Soon',
                          color: AppColors.warning),
                      _OverviewCard(
                          icon: Icons.bookmark_added_rounded,
                          value: '${stats.reservedBooks}',
                          label: 'Reserved Books',
                          color: AppColors.secondary),
                    ],
                  ),
                  loading: () => const _CardSkeleton(height: 170),
                  error: (e, _) =>
                      _ErrorCard(message: 'Could not load stats: $e'),
                ),
                const SizedBox(height: 24),

                // ── Quick Actions ─────────────────────────────────────────────
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.count(
                  // 4 cols on tablet/desktop, same 4 on mobile but taller
                  crossAxisCount: isWide ? 4 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.0 : 0.62,
                  children: [
                    QuickActionTile(
                        icon: Icons.search_rounded,
                        label: 'Search\nBooks',
                        onTap: () =>
                            ref.read(staffNavIndexProvider.notifier).state = 1),
                    QuickActionTile(
                        icon: Icons.menu_book_rounded,
                        label: 'My\nBooks',
                        onTap: () =>
                            ref.read(staffNavIndexProvider.notifier).state = 2),
                    QuickActionTile(
                        icon: Icons.bookmark_add_outlined,
                        label: 'Reserve\nBook',
                        onTap: () =>
                            ref.read(staffNavIndexProvider.notifier).state = 1),
                    QuickActionTile(
                        icon: Icons.notifications_active_outlined,
                        label: 'Notifi-\ncations',
                        onTap: () =>
                            ref.read(staffNavIndexProvider.notifier).state = 3),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Activity Chart ────────────────────────────────────────────
                const SectionHeader(title: 'Activity Dashboard'),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => _StatsChart(
                    borrowedBooks: stats.borrowedBooks,
                    returnedBooks: stats.returnedBooks,
                    dueSoon: stats.dueSoon,
                    reservedBooks: stats.reservedBooks,
                  ),
                  loading: () => const _CardSkeleton(height: 260),
                  error: (e, _) =>
                      _ErrorCard(message: 'Could not load stats: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _OverviewCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart of today's activity, with the exact numbers as a legend below.
class _StatsChart extends StatelessWidget {
  final int borrowedBooks;
  final int returnedBooks;
  final int dueSoon;
  final int reservedBooks;
  const _StatsChart({
    required this.borrowedBooks,
    required this.returnedBooks,
    required this.dueSoon,
    required this.reservedBooks,
  });

  @override
  Widget build(BuildContext context) {
    final bars = [
      (label: 'Borrowed', value: borrowedBooks, color: AppColors.primary),
      (label: 'Returned', value: returnedBooks, color: AppColors.success),
      (label: 'Due Soon', value: dueSoon, color: AppColors.warning),
      (label: 'Reserved', value: reservedBooks, color: AppColors.secondary),
    ];
    final maxVal =
        bars.map((b) => b.value).fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVal + (maxVal * 0.25))
                    .clamp(1, double.infinity)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: const SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: const SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(bars[i].label,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i].value.toDouble(),
                          color: bars[i].color,
                          width: 28,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              for (final b in bars) _legendItem(b.color, b.label, b.value)
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ',
            style:
                TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        Text('$value',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.4)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 12.5))),
        ],
      ),
    );
  }
}
