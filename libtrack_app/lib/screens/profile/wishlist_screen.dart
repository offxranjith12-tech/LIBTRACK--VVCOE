import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/responsive.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(wishlistBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: books.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 56, color: AppColors.textGrey),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart icon on any book in Search to add it here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/search'),
                      child: const Text('Browse Books'),
                    ),
                  ],
                ),
              ),
            )
          : ResponsiveCenter(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final book = books[i];
                  return BookCard(
                    book: book,
                    onViewDetails: () => context.push('/book/${book.id}'),
                    onReserve: () async {
                      final error = await ref.read(reservationsProvider.notifier).reserve(book);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? '"${book.title}" reserved successfully')),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
