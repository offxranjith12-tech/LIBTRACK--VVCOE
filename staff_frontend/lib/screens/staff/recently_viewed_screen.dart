import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/shared_widgets.dart';

/// Books the staff member has recently opened via Book Details, most
/// recent first.
class RecentlyViewedScreen extends ConsumerWidget {
  const RecentlyViewedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(recentlyViewedBooksProvider);
    final allBooksAsync = ref.watch(allBooksProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Recently Viewed', showBack: true),
      body: allBooksAsync.when(
        data: (_) => books.isEmpty
            ? const EmptyState(
                icon: Icons.history_rounded,
                message: 'No books viewed yet.\nBooks you open from Search will show up here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final book = books[i];
                  return BookCard(
                    book: book,
                    onViewDetails: () => context.push('/book/${book.id}'),
                    onReserve: () => context.push('/join-queue', extra: book),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load recently viewed books: $e', style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
    );
  }
}
