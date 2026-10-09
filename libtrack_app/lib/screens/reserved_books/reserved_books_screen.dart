import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';

class ReservedBooksScreen extends ConsumerWidget {
  const ReservedBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationsProvider);
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Reserved Books')),
      body: reservations.isEmpty
          ? Center(
              child: Text('No active reservations', style: Theme.of(context).textTheme.bodyMedium),
            )
          : ResponsiveCenter(
              padding: EdgeInsets.zero,
              child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = reservations[i];
                return SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BookCover(title: r.book.title, colorHex: r.book.coverColorHex, width: 56, height: 78),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.book.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                                Text(r.book.author, style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Text('Reserved on: ${df.format(r.reservationDate)}', style: Theme.of(context).textTheme.bodySmall),
                                Text('Expected: ${df.format(r.expectedAvailability)}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('#${r.queuePosition} in queue',
                                style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w700, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final error = await ref.read(reservationsProvider.notifier).cancel(r.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error ?? 'Reservation for "${r.book.title}" cancelled')),
                            );
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel Reservation'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
    );
  }
}
