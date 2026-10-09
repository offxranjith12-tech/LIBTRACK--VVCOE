import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/shared_widgets.dart';

class BookDetailsScreen extends ConsumerStatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends ConsumerState<BookDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedProvider.notifier).recordView(widget.book.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final saved = ref.watch(savedBooksProvider).contains(book.id);
    final available = book.availableCopies > 0;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Book Details',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: saved ? AppColors.primary : null),
            onPressed: () => ref.read(savedBooksProvider.notifier).toggle(book.id),
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Center(
            child: Container(
              width: 130,
              height: 176,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 18),
          Text(book.title,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('by ${book.author}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                StatusBadge(status: book.status),
                if (book.regulation.isNotEmpty) _regulationBadge(book.regulation),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _infoCard([
            _row('Publisher', book.publisher),
            _row('ISBN', book.isbn),
            _row('Category', book.category),
            if (book.regulation.isNotEmpty) _row('Regulation', book.regulation),
            _row('Department', book.department),
            _row('Rack Number', book.rack),
            _row('Shelf Number', book.shelf),
            _row('Total Copies', '${book.totalCopies}'),
            _row('Available Copies', '${book.availableCopies}'),
          ]),
          const SizedBox(height: 16),

          const SectionHeader(title: 'Description'),
          const SizedBox(height: 8),
          Text(
            book.description.isEmpty ? 'No description available for this title.' : book.description,
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/join-queue', extra: book),
              icon: Icon(available ? Icons.bookmark_add_outlined : Icons.hourglass_bottom_rounded, size: 18),
              label: Text(available ? 'Borrow This Book' : 'Join Queue for This Book'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _regulationBadge(String regulation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(regulation,
          style: const TextStyle(color: AppColors.secondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }
}
