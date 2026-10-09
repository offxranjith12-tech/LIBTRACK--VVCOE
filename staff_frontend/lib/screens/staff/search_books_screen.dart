import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/shared_widgets.dart';

class SearchBooksScreen extends ConsumerStatefulWidget {
  const SearchBooksScreen({super.key});

  @override
  ConsumerState<SearchBooksScreen> createState() => _SearchBooksScreenState();
}

class _SearchBooksScreenState extends ConsumerState<SearchBooksScreen> {
  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(filteredBooksProvider);
    final allBooksAsync = ref.watch(allBooksProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    // Every picker below is derived from whatever the catalog actually
    // contains (mirrors the Student Module's Search screen), so new
    // authors/racks/regulations show up automatically as books are added.
    final categories = allBooksAsync.maybeWhen(
      data: (books) =>
          books.map((b) => b.category).where((c) => c.isNotEmpty).toSet().toList()
            ..sort(),
      orElse: () => <String>[],
    );
    final authors = allBooksAsync.maybeWhen(
      data: (books) =>
          books.map((b) => b.author).where((a) => a.isNotEmpty).toSet().toList()
            ..sort(),
      orElse: () => <String>[],
    );
    final racks = allBooksAsync.maybeWhen(
      data: (books) =>
          books.map((b) => b.rack).where((r) => r.isNotEmpty).toSet().toList()
            ..sort(),
      orElse: () => <String>[],
    );
    final regulations = allBooksAsync.maybeWhen(
      data: (books) =>
          books.map((b) => b.regulation).where((r) => r.isNotEmpty).toSet().toList()
            ..sort(),
      orElse: () => <String>[],
    );

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 20, 12, isWide ? 28 : 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search Books',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                      decoration: const InputDecoration(
                        hintText: 'Search by title, author, or ISBN...',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _pickerChip(context,
                              label: 'Category',
                              filterKey: 'category',
                              icon: Icons.category_outlined,
                              options: categories),
                          const SizedBox(width: 8),
                          _pickerChip(context,
                              label: 'Author',
                              filterKey: 'author',
                              icon: Icons.person_outline_rounded,
                              options: authors),
                          const SizedBox(width: 8),
                          _pickerChip(context,
                              label: 'Rack',
                              filterKey: 'rack',
                              icon: Icons.shelves,
                              options: racks),
                          const SizedBox(width: 8),
                          _pickerChip(context,
                              label: 'Department',
                              filterKey: 'department',
                              icon: Icons.apartment_outlined,
                              options: const ['CSE', 'ECE', 'MECH', 'Common']),
                          const SizedBox(width: 8),
                          _pickerChip(context,
                              label: 'Regulation',
                              filterKey: 'regulation',
                              icon: Icons.menu_book_rounded,
                              options: regulations),
                          const SizedBox(width: 8),
                          _availabilityChip(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: booksAsync.when(
                  data: (books) => books.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          message: 'No books match your search.')
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              isWide ? 28 : 20, 8, isWide ? 28 : 20, 20),
                          itemCount: books.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final book = books[i];
                            return BookCard(
                              book: book,
                              onViewDetails: () =>
                                  context.push('/book/${book.id}'),
                              onReserve: () =>
                                  context.push('/join-queue', extra: book),
                            );
                          },
                        ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load books: $e',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.danger)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A filter chip that opens a bottom sheet listing the given options
  /// (Category, Author, Rack, Department, Regulation all use this).
  Widget _pickerChip(BuildContext context,
      {required String label,
      required String filterKey,
      required IconData icon,
      required List<String> options}) {
    final current = ref.watch(bookFiltersProvider);
    final active = current[filterKey];
    return ActionChip(
      label: Text(active ?? label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
      avatar: Icon(icon,
          size: 16, color: active != null ? Colors.white : AppColors.primary),
      backgroundColor: active != null ? AppColors.primary : AppColors.card,
      labelStyle: TextStyle(
        color: active != null ? Colors.white : AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
            color: active != null ? AppColors.primary : Colors.grey.shade200),
      ),
      onPressed: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) =>
              _OptionsSheet(title: label, options: options, selected: active),
        );
        if (selected == null) return;
        final updated = Map<String, String>.from(current);
        if (selected == 'All') {
          updated.remove(filterKey);
        } else {
          updated[filterKey] = selected;
        }
        ref.read(bookFiltersProvider.notifier).state = updated;
      },
    );
  }

  Widget _availabilityChip(BuildContext context) {
    final current = ref.watch(bookFiltersProvider);
    final selected = current['availability'] == 'available';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: const Text('Available'),
        selected: selected,
        onSelected: (v) {
          final updated = Map<String, String>.from(current);
          if (v) {
            updated['availability'] = 'available';
          } else {
            updated.remove('availability');
          }
          ref.read(bookFiltersProvider.notifier).state = updated;
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(
              color: selected ? AppColors.primary : Colors.grey.shade200),
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  const _OptionsSheet(
      {required this.title, required this.options, required this.selected});

  @override
  Widget build(BuildContext context) {
    final items = ['All', ...options];
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Filter by $title',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final o = items[i];
                  final isSelected = o == (selected ?? 'All');
                  return ListTile(
                    title: Text(o),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context, o),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
