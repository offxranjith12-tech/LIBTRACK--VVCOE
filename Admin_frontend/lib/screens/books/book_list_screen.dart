import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/auth/permissions.dart';
import '../../providers/book_provider.dart';
import '../../providers/remote_book_search_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/alerts_action_button.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/book_card.dart';

/// Book Management screen — searches and lists books straight from the
/// live backend (MySQL via `GET /books/search`), not local mock data.
/// Handles a 10,000+ row catalogue via server-side pagination.
class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(bookFilterProvider);
    final searchState = ref.watch(bookSearchControllerProvider);
    final role = ref.watch(currentRoleProvider);
    final canManage = Permissions.canManageBooks(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Management'),
        actions: [
          const AlertsActionButton(),
          const SizedBox(width: 4),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Bulk Import',
              onPressed: () => context.push('/books/import'),
            ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/books/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSearchField(
              hintText: 'Search by title, author, ISBN, regulation...',
              onChanged: (v) => ref.read(bookFilterProvider.notifier).state = filter.copyWith(query: v),
            ),
          ),
          // Wrapped in a fixed-height horizontal scroller with a compact chip
          // theme so the row never overflows vertically on smaller phones —
          // the default Chip padding was taller than the old 40px box.
          // The MediaQuery override locks text scale to 1.0 *for this row
          // only*: phones with a larger system font-size setting were
          // pushing chip labels to two lines inside the fixed-height box,
          // which is what caused the RenderFlex "overflow" glitch here.
          SizedBox(
            height: 44,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Theme(
                data: Theme.of(context).copyWith(
                  chipTheme: Theme.of(context).chipTheme.copyWith(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),

                      ),
                ),
                child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _FilterChip(
                    label: filter.category ?? 'Category',
                    active: filter.category != null,
                    onTap: () => _showPicker(context, 'Category', AppConstants.categories, filter.category, (v) {
                      ref.read(bookFilterProvider.notifier).state = filter.copyWith(category: v);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: filter.department ?? 'Department',
                    active: filter.department != null,
                    onTap: () => _showPicker(context, 'Department', AppConstants.departments, filter.department, (v) {
                      ref.read(bookFilterProvider.notifier).state = filter.copyWith(department: v);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: filter.regulation ?? 'Regulation',
                    active: filter.regulation != null,
                    onTap: () => _showPicker(context, 'Regulation', AppConstants.regulations, filter.regulation, (v) {
                      ref.read(bookFilterProvider.notifier).state = filter.copyWith(regulation: v);
                    }),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: const Text('Available only'),
                    selected: filter.onlyAvailable,
                    onSelected: (v) => ref.read(bookFilterProvider.notifier).state = filter.copyWith(onlyAvailable: v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: const Text('Issued only'),
                    selected: filter.onlyIssued,
                    onSelected: (v) => ref.read(bookFilterProvider.notifier).state = filter.copyWith(onlyIssued: v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: const Text('Low stock'),
                    selected: filter.onlyLowStock,
                    onSelected: (v) => ref.read(bookFilterProvider.notifier).state = filter.copyWith(onlyLowStock: v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: searchState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () => ref.read(bookSearchControllerProvider.notifier).refresh(),
              ),
              data: (result) {
                if (result.books.isEmpty) {
                  return Center(child: Text('No books found', style: TextStyle(color: AppColors.textSecondary)));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(bookSearchControllerProvider.notifier).refresh(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                        ref.read(bookSearchControllerProvider.notifier).loadNextPage();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: result.books.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == result.books.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                '${result.totalElements} book${result.totalElements == 1 ? "" : "s"} total',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          );
                        }
                        final book = result.books[index];
                        return BookCard(
                          book: book,
                          canManage: canManage,
                          onTap: () => context.push('/books/${book.id}'),
                          onEdit: canManage ? () => context.push('/books/${book.id}/edit') : null,
                          onIssue: canManage ? () => context.push('/transactions/issue?bookId=${book.id}') : null,
                          onDelete: !canManage
                              ? null
                              : () async {
                                  try {
                                    await ref.read(bookRemoteServiceProvider).delete(book.id);
                                    ref.read(bookSearchControllerProvider.notifier).refresh();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${book.title} deleted')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                    }
                                  }
                                },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, String title, List<String> options, String? current, ValueChanged<String?> onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Bounded to 70% of the screen height and scrollable — long option
        // lists (e.g. Department, Regulation) no longer push past the
        // bottom of the sheet and trigger a RenderFlex overflow.
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        title: const Text('All'),
                        trailing: current == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                        onTap: () {
                          onSelected(null);
                          Navigator.pop(context);
                        },
                      ),
                      for (final o in options)
                        ListTile(
                          title: Text(o),
                          trailing: current == o ? const Icon(Icons.check, color: AppColors.primary) : null,
                          onTap: () {
                            onSelected(o);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Could not load books', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Make sure the LibTrack backend is running and reachable.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(Icons.arrow_drop_down, size: 18, color: active ? AppColors.primary : AppColors.textSecondary),
      backgroundColor: active ? AppColors.primary.withValues(alpha: 0.12) : null,
      labelStyle: TextStyle(color: active ? AppColors.primary : AppColors.text),
      onPressed: onTap,
    );
  }
}
