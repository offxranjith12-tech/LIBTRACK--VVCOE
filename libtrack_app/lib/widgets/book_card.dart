import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'book_cover.dart';
import 'soft_card.dart';
import 'status_badge.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback onViewDetails;
  final VoidCallback onReserve;

  const BookCard({
    super.key,
    required this.book,
    required this.onViewDetails,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWishlisted = ref.watch(wishlistProvider).contains(book.id);

    return SoftCard(
      onTap: onViewDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(title: book.title, colorHex: book.coverColorHex),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => ref.read(wishlistProvider.notifier).toggle(book.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isWishlisted ? AppColors.primaryRed : AppColors.textGrey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(book.author, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(context, book.category),
                        _tag(context, 'Rack ${book.rackNumber}'),
                        _tag(context, 'Shelf ${book.shelfNumber}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(availability: book.availability),
                        const SizedBox(width: 8),
                        Text('${book.availableCopies}/${book.totalCopies} copies',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: book.availability == BookAvailability.available ? onReserve : onReserve,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: Text(book.availability == BookAvailability.available ? 'Reserve' : 'Join Queue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
    );
  }
}
