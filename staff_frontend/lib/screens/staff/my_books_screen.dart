import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/staff_providers.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// "My Books" tab: shows the staff member's active reservations
/// (books ready to collect and books waiting in queue).
class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  Future<void> _cancel(
      WidgetRef ref, BuildContext context, Reservation r) async {
    try {
      await ref.read(reservationServiceProvider).cancel(r.id);
      ref.invalidate(myReservationsProvider);
      ref.invalidate(myHistoryReservationsProvider);
      ref.invalidate(dashboardStatsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(myReservationsProvider);
    final historyAsync = ref.watch(myHistoryReservationsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 20, 12, isWide ? 28 : 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Books',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text("Books you've reserved or borrowed",
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5)),
                      const SizedBox(height: 16),
                      _actionCard(
                        icon: Icons.search_rounded,
                        label: 'Search & Borrow Books',
                        color: AppColors.primary,
                        onTap: () => ref
                            .read(staffNavIndexProvider.notifier)
                            .state = 1,
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(context, ref, reservationsAsync, isWide, false),
                      _buildList(context, ref, historyAsync, isWide, true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, AsyncValue<List<Reservation>> asyncValue, bool isWide, bool isHistory) {
    return asyncValue.when(
      data: (reservations) => reservations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    message: isHistory ? 'No book history found.' : 'You have no active books.'),
                const SizedBox(height: 16),
                if (!isHistory)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(staffNavIndexProvider.notifier)
                          .state = 1,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Browse Book Catalog'),
                    ),
                  ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  isWide ? 28 : 20, 8, isWide ? 28 : 20, 20),
              itemCount: reservations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _reservationCard(context, ref, reservations[i], isHistory),
            ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary)),
      error: (e, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          EmptyState(
              icon: Icons.error_outline,
              message: e.toString()),
        ],
      ),
    );
  }
  Widget _actionCard(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reservationCard(
      BuildContext context, WidgetRef ref, Reservation r, bool isHistory) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (r.isAvailable
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHistory ? Icons.history_rounded : (r.isAvailable
                      ? Icons.check_circle_outline_rounded
                      : Icons.hourglass_bottom_rounded),
                  color: isHistory ? AppColors.textMuted : (
                      r.isAvailable ? AppColors.success : AppColors.warning),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      isHistory ? 'Archived Record' : (r.isAvailable
                          ? 'Available / Borrowed'
                          : 'Queue position #'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isHistory ? AppColors.textMuted : (r.isAvailable ? AppColors.success : AppColors.textMuted),
                          fontWeight: isHistory ? FontWeight.w400 : (r.isAvailable ? FontWeight.w600 : FontWeight.w400),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isHistory) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancel(ref, context, r),
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.danger),
                label: const Text('Cancel Request',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
