import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/me_remote_service.dart';
import '../../providers/dashboard_stats_provider.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/alerts_action_button.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/section_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(meProfileProvider);
    final adminName = admin.valueOrNull?.name.split(' ').first ?? '';
    final statsAsync = ref.watch(dashboardStatsRemoteProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(meProfileProvider.notifier).load();
            ref.invalidate(dashboardStatsRemoteProvider);
            ref.read(remoteTransactionsProvider.notifier).load();
            // Give the invalidated providers a moment to kick off their
            // fetches so the pull-to-refresh spinner doesn't vanish instantly.
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LibTrack', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        adminName.isEmpty ? AppConstants.libraryName : 'Hi, $adminName',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const AlertsActionButton(),
                ],
              ),
              const SizedBox(height: 18),
              _AdminProfileCard(admin: admin),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Overview'),
              statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary, size: 32),
                      const SizedBox(height: 8),
                      Text('Could not load dashboard stats.\n$err', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(dashboardStatsRemoteProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    StatCard(label: 'Available Books', value: '${stats.availableBooks}', icon: Icons.check_circle_outline, color: AppColors.success, onTap: () => context.push('/books')),
                    StatCard(label: 'Overdue Books', value: '${stats.overdueBooks}', icon: Icons.warning_amber_rounded, color: AppColors.danger, onTap: () => context.push('/transactions')),
                    StatCard(label: 'Fine Collection', value: '₹${stats.fineCollection.toStringAsFixed(0)}', icon: Icons.currency_rupee_rounded, color: AppColors.success, onTap: () => context.push('/fines')),
                    StatCard(label: 'Issued Books', value: '${stats.issuedBooks}', icon: Icons.assignment_turned_in_outlined, color: AppColors.warning, onTap: () => context.push('/transactions')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SectionHeader(title: 'Quick Actions'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickActionButton(label: 'Add Book', icon: Icons.add_box_rounded, onTap: () => context.push('/books/add')),
                    const SizedBox(width: 12),
                    QuickActionButton(label: 'Issue Book', icon: Icons.output_rounded, onTap: () => context.push('/transactions/issue')),
                    const SizedBox(width: 12),
                    QuickActionButton(label: 'Search Books', icon: Icons.search_rounded, onTap: () => context.push('/books')),
                    const SizedBox(width: 12),
                    QuickActionButton(label: 'Book Requests', icon: Icons.mark_email_unread_rounded, onTap: () => context.push('/book-requests')),
                    const SizedBox(width: 12),
                    QuickActionButton(label: 'Reports', icon: Icons.insert_chart_outlined_rounded, onTap: () => context.push('/reports')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SectionHeader(title: 'Recent Overdue', actionLabel: 'View all', onAction: () => context.push('/transactions')),
              const _RecentOverdueList(),
              const SizedBox(height: 20),
              _NotifyBottomCard(onTap: () => context.push('/notifications')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifyBottomCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NotifyBottomCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notify students & staff', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Send an announcement or alert', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  final AsyncValue<MeProfile> admin;
  const _AdminProfileCard({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: admin.when(
        loading: () => const Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 30)),
            SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
        error: (err, _) => Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Could not load your profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        data: (profile) {
          final avatarUrl = ApiClient.instance.resolveFileUrl(profile.avatarUrl);
          return Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('ID: ${profile.loginId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(AppConstants.libraryName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      profile.role == 'ADMIN' ? 'Administrator' : profile.role == 'LIBRARIAN' ? 'Librarian' : profile.role == 'STAFF' ? 'Staff' : 'Student',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecentOverdueList extends ConsumerWidget {
  const _RecentOverdueList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(remoteTransactionsProvider);
    return transactionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Text('Could not load overdue books', style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (transactions) {
        final overdue = transactions.where((t) => t.status == TransactionStatus.overdue).toList();
        if (overdue.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Text('No overdue books 🎉', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return Column(
          children: overdue.take(3).map((t) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${t.borrowerName} • ${t.overdueDays} days overdue', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('₹${t.fineAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
