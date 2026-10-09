import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/dashboard_service.dart';
import '../services/feedback_service.dart';
import '../services/library_service.dart';
import '../services/notification_service.dart';
import '../services/reservation_service.dart';
import '../services/staff_service.dart';

/// Every provider below now calls the real Spring Boot backend (see
/// lib/services/*.dart) instead of returning mock data. Screens read these
/// as AsyncValue and render loading/error/data states with `.when(...)`.

// ---- Service instances (stateless, cheap to construct) ----
final authServiceProvider = Provider((ref) => AuthService());
final staffServiceProvider = Provider((ref) => StaffService());
final dashboardServiceProvider = Provider((ref) => DashboardService());
final bookServiceProvider = Provider((ref) => BookService());
final reservationServiceProvider = Provider((ref) => ReservationService());
final notificationServiceProvider = Provider((ref) => NotificationService());
final feedbackServiceProvider = Provider((ref) => FeedbackService());
final libraryServiceProvider = Provider((ref) => LibraryService());

// ---- Auth ----

/// True once a JWT is cached; the router's redirect guard watches this.
final isLoggedInProvider = FutureProvider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoggedIn;
});

// ---- Dashboard / Profile ----

final currentStaffProvider = FutureProvider<Staff>((ref) {
  return ref.watch(staffServiceProvider).getProfile();
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(dashboardServiceProvider).getStats();
});

// ---- Books / Search ----

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active filter chips on the Search Books screen (Category, Department,
/// Author, Rack, Shelf, Availability), keyed by chip label.
final bookFiltersProvider = StateProvider<Map<String, String>>((ref) => {});

final filteredBooksProvider = FutureProvider<List<Book>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(bookFiltersProvider);
  return ref.watch(bookServiceProvider).search(
        query: query,
        category: filters['category'],
        department: filters['department'],
        author: filters['author'],
        rack: filters['rack'],
        shelf: filters['shelf'],
        regulation: filters['regulation'],
        availability: filters['availability'],
      );
});

final bookDetailsProvider = FutureProvider.family<Book, String>((ref, id) {
  return ref.watch(bookServiceProvider).getById(id);
});

/// Unfiltered catalog — powers the "Select Book" dropdown on Issue Book,
/// the Search screen's category picker, and the Saved Books screen.
final allBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(bookServiceProvider).search();
});

// ---- Saved Books (staff's personal bookmarks) ----
// Local-only, persisted on-device with shared_preferences - distinct from
// the "Wishlist" (Recommend a Book to acquire) feature, which is backend-backed.

class SavedBooksNotifier extends StateNotifier<Set<String>> {
  SavedBooksNotifier() : super(<String>{}) {
    _load();
  }

  static const _prefsKey = 'staff_saved_book_ids';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null) state = saved.toSet();
  }

  Future<void> toggle(String bookId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(bookId)) {
      updated.remove(bookId);
    } else {
      updated.add(bookId);
    }
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated.toList());
  }
}

final savedBooksProvider = StateNotifierProvider<SavedBooksNotifier, Set<String>>((ref) => SavedBooksNotifier());

/// Books currently saved, resolved against the live catalog.
final savedBooksListProvider = Provider<List<Book>>((ref) {
  final ids = ref.watch(savedBooksProvider);
  final booksAsync = ref.watch(allBooksProvider);
  return booksAsync.maybeWhen(
    data: (books) => books.where((b) => ids.contains(b.id)).toList(),
    orElse: () => <Book>[],
  );
});

// ---- Recently Viewed Books ----
// Local-only, persisted on-device - tracks books opened via Book Details.

class RecentlyViewedNotifier extends StateNotifier<List<String>> {
  RecentlyViewedNotifier() : super(<String>[]) {
    _load();
  }

  static const _prefsKey = 'staff_recently_viewed_book_ids';
  static const _maxItems = 20;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null) state = saved;
  }

  Future<void> recordView(String bookId) async {
    final updated = [bookId, ...state.where((id) => id != bookId)].take(_maxItems).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated);
  }
}

final recentlyViewedProvider = StateNotifierProvider<RecentlyViewedNotifier, List<String>>((ref) => RecentlyViewedNotifier());

/// Recently viewed books, resolved against the live catalog, most recent first.
final recentlyViewedBooksProvider = Provider<List<Book>>((ref) {
  final ids = ref.watch(recentlyViewedProvider);
  final booksAsync = ref.watch(allBooksProvider);
  return booksAsync.maybeWhen(
    data: (books) {
      final byId = {for (final b in books) b.id: b};
      return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
    },
    orElse: () => <Book>[],
  );
});

// ---- Reservations ----

/// Only the logged-in staff member's own active reservations - used by
/// "My Reservations".
final myReservationsProvider = FutureProvider<List<Reservation>>((ref) {
  return ref.watch(reservationServiceProvider).getMine();
});

final myHistoryReservationsProvider = FutureProvider<List<Reservation>>((ref) {
  return ref.watch(reservationServiceProvider).getHistory();
});

// ---- Notifications ----

final notificationsProvider = FutureProvider<List<LibNotification>>((ref) {
  return ref.watch(notificationServiceProvider).getAll();
});

// ---- Feedback ----

final feedbackListProvider = FutureProvider<List<FeedbackEntry>>((ref) {
  return ref.watch(feedbackServiceProvider).getAll();
});

// ---- Library Timings & Rules ----

final libraryTimingsProvider = FutureProvider<LibraryTimings>((ref) {
  return ref.watch(libraryServiceProvider).getTimings();
});

final libraryRulesProvider = FutureProvider<LibraryRules>((ref) {
  return ref.watch(libraryServiceProvider).getRules();
});

/// Bottom navigation index for the staff shell.
final staffNavIndexProvider = StateProvider<int>((ref) => 0);
