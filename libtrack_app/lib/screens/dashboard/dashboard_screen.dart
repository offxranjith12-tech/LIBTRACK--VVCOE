import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/responsive.dart';
import '../../widgets/section_title.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/student_avatar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final connection = ref.watch(connectionStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(studentProvider.notifier).refresh(),
              ref.read(allBooksProvider.notifier).refresh(),
              ref.read(borrowedBooksProvider.notifier).refresh(),
              ref.read(reservationsProvider.notifier).refresh(),
              ref.read(notificationsProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (connection.state == BackendConnectionState.failed || connection.state == BackendConnectionState.connected)
                ResponsiveCenter(child: _ConnectionBanner(status: connection)),
              ResponsiveCenter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _Header(unread: unread, onNotifications: () => context.go('/notifications')),
                    const SizedBox(height: 16),
                    _ProfileCard(name: student.name, reg: student.registerNumber, dept: student.department, sem: student.semester, photoUrl: student.photoUrl),
                    const SizedBox(height: 20),
                    const SectionTitle(title: 'Overview'),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = responsiveColumns(constraints.maxWidth, min: 2, max: 4, tileWidth: 230);
                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            // Fixed pixel height per card (not an aspect ratio) so the
                            // card can never run out of vertical room and overflow,
                            // no matter the screen width or system font scale.
                            mainAxisExtent: 118,
                          ),
                          children: [
                            StatCard(icon: Icons.menu_book_rounded, label: 'Borrowed Books', value: '${stats.borrowed}', color: AppColors.primaryRed),
                            StatCard(icon: Icons.bookmark_rounded, label: 'Reserved Books', value: '${stats.reserved}', color: const Color(0xFF1565C0)),
                            StatCard(icon: Icons.hourglass_bottom_rounded, label: 'Due Soon', value: '${stats.dueSoon}', color: AppColors.warning),
                            StatCard(icon: Icons.currency_rupee_rounded, label: 'Pending Fine', value: '₹${stats.pendingFine.toStringAsFixed(0)}', color: AppColors.danger),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle(title: 'Quick Actions'),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          QuickActionButton(icon: Icons.search_rounded, label: 'Search\nBooks', onTap: () => context.go('/search')),
                          QuickActionButton(icon: Icons.menu_book_rounded, label: 'My\nBooks', onTap: () => context.go('/my-books')),
                          QuickActionButton(icon: Icons.bookmark_add_rounded, label: 'Reserve\nBook', onTap: () => context.push('/reserved-books')),
                          QuickActionButton(icon: Icons.notifications_active_rounded, label: 'Notifi-\ncations', onTap: () => context.go('/notifications')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle(title: 'Activity Dashboard'),
                    _ActivityDashboard(stats: stats),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extra dashboard section with a bar chart of borrow/return activity plus
/// a compact legend with the exact numbers (borrowed, returned, overdue,
/// fine). Responsive: the chart grows on wider screens instead of the
/// tiles wrapping into extra rows.
class _ActivityDashboard extends StatelessWidget {
  final DashboardStats stats;
  const _ActivityDashboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bars = <_BarDatum>[
      _BarDatum('Borrowed', stats.totalBorrowedAllTime.toDouble(), AppColors.primaryRed),
      _BarDatum('Returned', stats.totalReturned.toDouble(), AppColors.success),
      _BarDatum('Overdue', stats.overdueCount.toDouble(), AppColors.danger),
      _BarDatum('Reserved', stats.reserved.toDouble(), const Color(0xFF1565C0)),
    ];
    final maxVal = bars.map((b) => b.value).fold<double>(1, (a, b) => a > b ? a : b);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + (maxVal * 0.25).clamp(1, 10),
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxVal / 4).clamp(1, double.infinity).ceilToDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.textGrey.withOpacity(0.12), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxVal / 4).clamp(1, double.infinity).ceilToDouble(),
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(bars[i].label, style: const TextStyle(fontSize: 10.5, color: AppColors.textGrey)),
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
                          toY: bars[i].value,
                          color: bars[i].color,
                          width: 26,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              for (final b in bars) _LegendItem(color: b.color, label: b.label, value: b.value.toInt().toString()),
              _LegendItem(color: AppColors.warning, label: 'Total Fine', value: '₹${stats.pendingFine.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarDatum {
  final String label;
  final double value;
  final Color color;
  const _BarDatum(this.label, this.value, this.color);
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final ConnectionStatus status;
  const _ConnectionBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isFailed = status.state == BackendConnectionState.failed;
    final color = isFailed ? AppColors.danger : AppColors.success;
    final icon = isFailed ? Icons.cloud_off_rounded : Icons.cloud_done_rounded;
    final title = isFailed ? 'Could not reach backend - showing demo data' : 'Connected to backend';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
                if (isFailed && status.errorMessage != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    status.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color.withOpacity(0.85), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unread;
  final VoidCallback onNotifications;
  const _Header({required this.unread, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LibTrack', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryRed)),
            Text('VV College of Engineering', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name, reg, dept, sem;
  final String? photoUrl;
  const _ProfileCard({required this.name, required this.reg, required this.dept, required this.sem, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryRed.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          StudentAvatar(photoUrl: photoUrl, name: name, radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Reg No: $reg', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(dept, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
                Text(sem, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
