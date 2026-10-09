import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/responsive.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(filteredBooksProvider);
    final filters = ref.watch(bookSearchFiltersProvider);
    final allBooks = ref.watch(allBooksProvider);

    final categories = ['All', ...{for (final b in allBooks) b.category}];
    final departments = ['All', ...{for (final b in allBooks) b.department}];
    final authors = ['All', ...{for (final b in allBooks) b.author}];
    final racks = ['All', ...{for (final b in allBooks) b.rackNumber}];

    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: ResponsiveCenter(
        padding: EdgeInsets.zero,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (v) => ref.read(bookSearchFiltersProvider.notifier).state = filters.copyWith(query: v),
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          ref.read(bookSearchFiltersProvider.notifier).state = filters.copyWith(query: '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _regulationChip(context, filters),
                const SizedBox(width: 8),
                _filterChip(context, 'Category', filters.category, categories,
                    (v) => ref.read(bookSearchFiltersProvider.notifier).state = filters.copyWith(category: v)),
                const SizedBox(width: 8),
                _filterChip(context, 'Department', filters.department, departments,
                    (v) => ref.read(bookSearchFiltersProvider.notifier).state = filters.copyWith(department: v)),
                const SizedBox(width: 8),
                _filterChip(context, 'Author', filters.author, authors,
                    (v) => ref.read(bookSearchFiltersProvider.notifier).state = filters.copyWith(author: v)),
                const SizedBox(width: 8),
                _filterChip(context, 'Rack', filters.rack, racks,
                    (v) => ref.read(bookSearchFiltersProvider.notifier).state = filters.copyWith(rack: v)),
                const SizedBox(width: 8),
                _availabilityChip(context, filters),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: books.isEmpty
                ? Center(
                    child: Text('No books match your filters', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final book = books[i];
                      return BookCard(
                        book: book,
                        onViewDetails: () => context.push('/book/${book.id}'),
                        onReserve: () => _reserve(context, book),
                      );
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _reserve(BuildContext context, Book book) async {
    final error = await ref.read(reservationsProvider.notifier).reserve(book);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '"${book.title}" reserved successfully')),
    );
  }

  Widget _regulationChip(BuildContext context, BookSearchFilters filters) {
    final active = filters.category == 'Regulation';
    return ActionChip(
      label: const Text('Regulation Books'),
      avatar: Icon(Icons.menu_book_rounded, size: 16, color: active ? Colors.white : AppColors.primaryRed),
      backgroundColor: active ? AppColors.primaryRed : AppColors.surfaceLight,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.textDark, fontSize: 12.5, fontWeight: FontWeight.w600),
      onPressed: () {
        ref.read(bookSearchFiltersProvider.notifier).state =
            filters.copyWith(category: active ? 'All' : 'Regulation');
      },
    );
  }

  Widget _filterChip(BuildContext context, String label, String value, List<String> options, ValueChanged<String> onSelect) {
    final active = value != 'All';
    return ActionChip(
      label: Text(active ? '$label: $value' : label),
      avatar: Icon(Icons.filter_list_rounded, size: 16, color: active ? Colors.white : AppColors.primaryRed),
      backgroundColor: active ? AppColors.primaryRed : AppColors.surfaceLight,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.textDark, fontSize: 12.5),
      onPressed: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => _OptionsSheet(title: label, options: options, selected: value),
        );
        if (selected != null) onSelect(selected);
      },
    );
  }

  Widget _availabilityChip(BuildContext context, BookSearchFilters filters) {
    final active = filters.availability != null;
    final label = filters.availability == null
        ? 'Availability'
        : filters.availability == BookAvailability.available
            ? 'Available'
            : 'Issued';
    return ActionChip(
      label: Text(label),
      avatar: Icon(Icons.check_circle_outline_rounded, size: 16, color: active ? Colors.white : AppColors.primaryRed),
      backgroundColor: active ? AppColors.primaryRed : AppColors.surfaceLight,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.textDark, fontSize: 12.5),
      onPressed: () {
        final notifier = ref.read(bookSearchFiltersProvider.notifier);
        if (filters.availability == null) {
          notifier.state = filters.copyWith(availability: BookAvailability.available);
        } else if (filters.availability == BookAvailability.available) {
          notifier.state = filters.copyWith(availability: BookAvailability.issued);
        } else {
          notifier.state = filters.copyWith(clearAvailability: true);
        }
      },
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  const _OptionsSheet({required this.title, required this.options, required this.selected});

  @override
  Widget build(BuildContext context) {
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
              child: Text('Filter by $title', style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final o = options[i];
                  return ListTile(
                    title: Text(o),
                    trailing: o == selected ? const Icon(Icons.check_rounded, color: AppColors.primaryRed) : null,
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
