import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/shared_widgets.dart';

/// Wishlist — books the staff member has personally bookmarked (heart icon
/// on Book Details / Search results), same concept as the Student Module's
/// Wishlist. (The class name stays SavedBooksScreen internally; only the
/// user-facing title changed to "Wishlist".)
class SavedBooksScreen extends ConsumerWidget {
  const SavedBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedBooks = ref.watch(savedBooksListProvider);
    final allBooksAsync = ref.watch(allBooksProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Wishlist', showBack: true),
      body: allBooksAsync.when(
        data: (_) => savedBooks.isEmpty
            ? const EmptyState(
                icon: Icons.favorite_border_rounded,
                message: 'Your wishlist is empty.\nTap the heart icon on any book to add it here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: savedBooks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final book = savedBooks[i];
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
            child: Text('Could not load your wishlist: $e', style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
    );
  }
}
