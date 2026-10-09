import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/book_remote_service.dart';
import 'book_provider.dart' show BookFilter, bookFilterProvider;
import 'service_providers.dart';

/// Drives the search bar against the real backend (`GET /books/search`).
/// Debounces keystrokes, supports paging through a large (10k+) catalogue,
/// and exposes loading/error states so the UI can show a clear message if
/// the backend isn't reachable.
class BookSearchController extends StateNotifier<AsyncValue<BookSearchResult>> {
  BookSearchController(this._service) : super(const AsyncValue.loading()) {
    search(const BookFilter());
  }

  final BookRemoteService _service;
  Timer? _debounce;
  BookFilter _filter = const BookFilter();
  int _page = 0;

  static const _pageSize = 20;

  /// Call on every filter/search-text change. Debounced by 400ms so rapid
  /// typing doesn't fire a request per keystroke.
  void search(BookFilter filter) {
    _filter = filter;
    _page = 0;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || _page + 1 >= current.totalPages) return;
    _page++;
    await _fetch(append: true);
  }

  Future<void> refresh() async {
    _page = 0;
    await _fetch();
  }

  Future<void> _fetch({bool append = false}) async {
    if (!append) state = const AsyncValue.loading();
    try {
      final result = await _service.search(
        query: _filter.query,
        category: _filter.category,
        department: _filter.department,
        regulation: _filter.regulation,
        onlyAvailable: _filter.onlyAvailable,
        onlyIssued: _filter.onlyIssued,
        onlyLowStock: _filter.onlyLowStock,
        page: _page,
        size: _pageSize,
      );

      if (append && state.hasValue) {
        final previous = state.value!;
        state = AsyncValue.data(BookSearchResult(
          books: [...previous.books, ...result.books],
          totalPages: result.totalPages,
          totalElements: result.totalElements,
          page: result.page,
        ));
      } else {
        state = AsyncValue.data(result);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final bookSearchControllerProvider = StateNotifierProvider<BookSearchController, AsyncValue<BookSearchResult>>((ref) {
  final controller = BookSearchController(ref.watch(bookRemoteServiceProvider));
  ref.listen(bookFilterProvider, (previous, next) => controller.search(next));
  return controller;
});
