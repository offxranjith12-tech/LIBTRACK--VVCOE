import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/borrowed_book.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';

class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(borrowedBooksProvider);
    final current = all.where((b) => b.status != BorrowStatus.returned).toList();
    final history = all.where((b) => b.status == BorrowStatus.returned).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Books'),
          bottom: const TabBar(
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primaryRed,
            tabs: [Tab(text: 'Current'), Tab(text: 'History')],
          ),
        ),
        body: TabBarView(
          children: [
            current.isEmpty
                ? const _EmptyState(text: 'No books currently borrowed')
                : ResponsiveCenter(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: current.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _CurrentBookCard(
                        borrow: current[i],
                        onRenew: () => _renew(context, ref, current[i]),
                      ),
                    ),
                  ),
            history.isEmpty
                ? const _EmptyState(text: 'No book history yet')
                : ResponsiveCenter(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _HistoryBookCard(borrow: history[i]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _renew(BuildContext context, WidgetRef ref, BorrowedBook borrow) async {
    final error = await ref.read(borrowedBooksProvider.notifier).renew(borrow.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '"${borrow.book.title}" renewed for 14 more days')),
    );
  }
}

class _CurrentBookCard extends StatelessWidget {
  final BorrowedBook borrow;
  final VoidCallback onRenew;
  const _CurrentBookCard({required this.borrow, required this.onRenew});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final overdue = borrow.status == BorrowStatus.overdue;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(title: borrow.book.title, colorHex: borrow.book.coverColorHex, width: 56, height: 78),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(borrow.book.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                    Text(borrow.book.author, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text('Borrowed: ${df.format(borrow.borrowDate)}', style: Theme.of(context).textTheme.bodySmall),
                    Text('Due: ${df.format(borrow.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (overdue ? AppColors.danger : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  overdue ? 'Overdue' : '${borrow.remainingDays}d left',
                  style: TextStyle(
                    color: overdue ? AppColors.danger : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          if (overdue) ...[
            const SizedBox(height: 10),
            Text('Fine: ₹${borrow.fineAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRenew,
              icon: const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('Renew Book'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBookCard extends StatelessWidget {
  final BorrowedBook borrow;
  const _HistoryBookCard({required this.borrow});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return SoftCard(
      child: Row(
        children: [
          BookCover(title: borrow.book.title, colorHex: borrow.book.coverColorHex, width: 48, height: 66),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(borrow.book.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text('Returned: ${borrow.returnDate != null ? df.format(borrow.returnDate!) : '-'}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Text('Returned', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
