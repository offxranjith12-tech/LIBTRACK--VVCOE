import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/mock/mock_data.dart';
import '../models/book.dart';

/// Sentinel used so [BookFilter.copyWith] can tell "leave this field alone"
/// apart from "explicitly clear this field to null" — a plain `?? this.x`
/// implementation can never set a nullable field back to null (e.g. picking
/// "All" in the Category/Department/Regulation sheet), which was the bug
/// behind "All" not actually showing every book again.
const Object _unset = Object();

class BookFilter {
  final String query;
  final String? category;
  final String? department;
  final String? regulation;
  final bool onlyAvailable;
  final bool onlyIssued;
  final bool onlyLowStock;

  const BookFilter({
    this.query = '',
    this.category,
    this.department,
    this.regulation,
    this.onlyAvailable = false,
    this.onlyIssued = false,
    this.onlyLowStock = false,
  });

  BookFilter copyWith({
    String? query,
    Object? category = _unset,
    Object? department = _unset,
    Object? regulation = _unset,
    bool? onlyAvailable,
    bool? onlyIssued,
    bool? onlyLowStock,
  }) {
    return BookFilter(
      query: query ?? this.query,
      category: identical(category, _unset) ? this.category : category as String?,
      department: identical(department, _unset) ? this.department : department as String?,
      regulation: identical(regulation, _unset) ? this.regulation : regulation as String?,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      onlyIssued: onlyIssued ?? this.onlyIssued,
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
    );
  }
}

class BooksNotifier extends StateNotifier<List<Book>> {
  BooksNotifier() : super(List.of(MockData.books));

  void addBook(Book book) => state = [book, ...state];

  /// Adds many books in a single state update — used by CSV/Excel bulk import
  /// so 5,000+ rows don't trigger 5,000 separate rebuilds.
  void addBooks(List<Book> books) => state = [...books, ...state];

  void updateBook(Book updated) {
    state = [
      for (final b in state) if (b.id == updated.id) updated else b,
    ];
  }

  void deleteBook(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  Book? findById(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  void adjustAvailability(String bookId, int delta) {
    state = [
      for (final b in state)
        if (b.id == bookId)
          b.copyWith(availableCopies: (b.availableCopies + delta).clamp(0, b.totalCopies))
        else
          b,
    ];
  }
}

final booksProvider = StateNotifierProvider<BooksNotifier, List<Book>>(
  (ref) => BooksNotifier(),
);

final bookFilterProvider = StateProvider<BookFilter>((ref) => const BookFilter());

final filteredBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(booksProvider);
  final filter = ref.watch(bookFilterProvider);

  return books.where((b) {
    final matchesQuery = filter.query.isEmpty ||
        b.title.toLowerCase().contains(filter.query.toLowerCase()) ||
        b.author.toLowerCase().contains(filter.query.toLowerCase()) ||
        b.isbn.contains(filter.query) ||
        b.regulation.toLowerCase().contains(filter.query.toLowerCase());
    final matchesCategory = filter.category == null || b.category == filter.category;
    final matchesDept = filter.department == null || b.department == filter.department;
    final matchesRegulation = filter.regulation == null || b.regulation == filter.regulation;
    final matchesAvailability = !filter.onlyAvailable || b.availableCopies > 0;
    final matchesIssued = !filter.onlyIssued || b.availableCopies < b.totalCopies;
    final matchesLowStock = !filter.onlyLowStock || (b.availableCopies > 0 && b.availableCopies <= 2);
    return matchesQuery && matchesCategory && matchesDept && matchesRegulation && matchesAvailability && matchesIssued && matchesLowStock;
  }).toList();
});
