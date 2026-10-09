import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/staff_providers.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final BookStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case BookStatus.available:
        color = AppColors.success;
        label = 'Available';
        break;
      case BookStatus.lowStock:
        color = AppColors.warning;
        label = 'Low Stock';
        break;
      case BookStatus.issued:
        color = AppColors.danger;
        label = 'Fully Issued';
        break;
      case BookStatus.reserved:
        color = AppColors.secondary;
        label = 'Reserved';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

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
    final saved = ref.watch(savedBooksProvider).contains(book.id);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
              ),
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
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => ref.read(savedBooksProvider.notifier).toggle(book.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: saved ? AppColors.primary : AppColors.textMuted,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(book.author,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(status: book.status),
                        if (book.regulation.isNotEmpty) _RegulationChip(label: book.regulation),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaChip(icon: Icons.category_outlined, label: book.category),
              _MetaChip(icon: Icons.shelves, label: 'Rack ${book.rack} • ${book.shelf}'),
              _MetaChip(icon: Icons.copy_all_outlined, label: '${book.availableCopies}/${book.totalCopies} copies'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onReserve,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(book.availableCopies > 0 ? 'Borrow' : 'Join Queue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegulationChip extends StatelessWidget {
  final String label;
  const _RegulationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
