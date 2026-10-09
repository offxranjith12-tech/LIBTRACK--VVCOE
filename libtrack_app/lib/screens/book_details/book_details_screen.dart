import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/book.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/status_badge.dart';

class BookDetailsScreen extends ConsumerWidget {
  final String bookId;
  const BookDetailsScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(allBooksProvider);
    final book = books.firstWhere((b) => b.id == bookId, orElse: () => books.first);
    final wishlist = ref.watch(wishlistProvider);
    final isWishlisted = wishlist.contains(book.id);

    // Track as recently viewed
    Future.microtask(() {
      final recents = ref.read(recentlyViewedProvider.notifier);
      final list = List<String>.from(ref.read(recentlyViewedProvider))..remove(book.id);
      list.insert(0, book.id);
      recents.state = list.take(10).toList();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ResponsiveCenter(
            maxWidth: 800,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          const SizedBox(height: 16),
          Center(child: BookCover(title: book.title, colorHex: book.coverColorHex, width: 120, height: 168)),
          const SizedBox(height: 18),
          Text(book.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('by ${book.author}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Center(child: StatusBadge(availability: book.availability)),
          const SizedBox(height: 20),
          SoftCard(
            child: Column(
              children: [
                _row(context, 'Publisher', book.publisher),
                _row(context, 'Edition', book.edition),
                _row(context, 'ISBN', book.isbn),
                _row(context, 'Department', book.department),
                _row(context, 'Category', book.category),
                _row(context, 'Rack Number', book.rackNumber),
                _row(context, 'Shelf Number', book.shelfNumber),
                _row(context, 'Total Copies', '${book.totalCopies}'),
                _row(context, 'Available Copies', '${book.availableCopies}', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(book.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final error = await ref.read(reservationsProvider.notifier).reserve(book);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? '"${book.title}" reserved successfully')),
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text('Reserve Book'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(wishlistProvider.notifier).toggle(book.id),
                  child: Icon(isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: AppColors.primaryRed),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Share.share('Check out "${book.title}" by ${book.author} on LibTrack!'),
                  child: const Icon(Icons.share_rounded, color: AppColors.primaryRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
