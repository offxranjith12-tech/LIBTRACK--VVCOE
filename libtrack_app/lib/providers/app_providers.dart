import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../models/borrowed_book.dart';
import '../models/notification_model.dart';
import '../models/reservation.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';

/// Shared API client. Every notifier below reads this to decide whether
/// to serve local demo data or call the real Spring Boot backend - see
/// api_service.dart's useMockData flag.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Lets the UI show whether the backend call actually succeeded, instead
/// of silently falling back to demo data with no visible sign anything
/// went wrong.
enum BackendConnectionState { unknown, connected, failed, usingMockData }

class ConnectionStatus {
  final BackendConnectionState state;
  final String? errorMessage;
  const ConnectionStatus(this.state, [this.errorMessage]);
}

final connectionStatusProvider = StateProvider<ConnectionStatus>(
  (ref) => const ConnectionStatus(BackendConnectionState.unknown),
);

/// Theme mode (light/dark) toggle
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);
  void toggle() => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

// ---------------------------------------------------------------------
// Student profile
// ---------------------------------------------------------------------

class StudentNotifier extends StateNotifier<Student> {
  StudentNotifier(this._ref) : super(MockDataService.currentStudent) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final api = _ref.read(apiServiceProvider);

    if (api.useMockData) {
      _ref.read(connectionStatusProvider.notifier).state =
          const ConnectionStatus(BackendConnectionState.usingMockData);
      return;
    }

    try {
      final fresh = await api.fetchStudent(state.id);
      state = fresh;
      _ref.read(connectionStatusProvider.notifier).state =
          const ConnectionStatus(BackendConnectionState.connected);
    } catch (e) {
      // Backend not reachable - keep whatever we already have (demo data
      // on first load) so the UI never breaks, but surface *why* so it's
      // no longer a silent failure.
      _ref.read(connectionStatusProvider.notifier).state =
          ConnectionStatus(BackendConnectionState.failed, e.toString());
    }
  }

  /// Called right after a successful login, since the login response
  /// already includes the full student record - no need for another fetch.
  void setStudent(Student student) {
    state = student;
  }

  /// Called by the Edit Profile screen after a successful save.
  Future<void> saveProfile({required String name, required String email, required String phone, String? photoPath}) async {
    final api = _ref.read(apiServiceProvider);
    String? newPhotoUrl = photoPath;
    try {
      if (photoPath != null && photoPath != state.photoUrl) {
        newPhotoUrl = await api.uploadProfileImage(state.id, photoPath);
      }
      final updated = await api.updateStudent(state.id, name: name, email: email, phone: phone);
      state = updated.copyWith(photoUrl: newPhotoUrl ?? updated.photoUrl);
    } catch (_) {
      // Backend not reachable - still apply the change locally so the
      // demo experience isn't broken.
      state = state.copyWith(name: name, email: email, phone: phone, photoUrl: photoPath);
    }
  }
}

final studentProvider = StateNotifierProvider<StudentNotifier, Student>((ref) => StudentNotifier(ref));

// ---------------------------------------------------------------------
// Book catalog
// ---------------------------------------------------------------------

class BooksNotifier extends StateNotifier<List<Book>> {
  BooksNotifier(this._ref) : super(MockDataService.books) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final api = _ref.read(apiServiceProvider);
    try {
      final books = await api.searchBooks();
      if (books.isNotEmpty) state = books;
    } catch (_) {
      // keep current (demo) catalog
    }
  }
}

final allBooksProvider = StateNotifierProvider<BooksNotifier, List<Book>>((ref) => BooksNotifier(ref));

/// Search filters state
class BookSearchFilters {
  final String query;
  final String category;
  final String department;
  final String author;
  final String rack;
  final BookAvailability? availability;

  const BookSearchFilters({
    this.query = '',
    this.category = 'All',
    this.department = 'All',
    this.author = 'All',
    this.rack = 'All',
    this.availability,
  });

  BookSearchFilters copyWith({
    String? query,
    String? category,
    String? department,
    String? author,
    String? rack,
    BookAvailability? availability,
    bool clearAvailability = false,
  }) =>
      BookSearchFilters(
        query: query ?? this.query,
        category: category ?? this.category,
        department: department ?? this.department,
        author: author ?? this.author,
        rack: rack ?? this.rack,
        availability: clearAvailability ? null : (availability ?? this.availability),
      );
}

final bookSearchFiltersProvider = StateProvider<BookSearchFilters>((ref) => const BookSearchFilters());

/// Filters whatever the current catalog is (mock or backend-fetched)
/// client-side - so this works identically whether or not the backend
/// is connected.
final filteredBooksProvider = Provider<List<Book>>((ref) {
  final f = ref.watch(bookSearchFiltersProvider);
  final source = ref.watch(allBooksProvider);
  return MockDataService.filterBooks(
    source,
    query: f.query,
    category: f.category,
    department: f.department,
    author: f.author,
    rack: f.rack,
    availability: f.availability,
  );
});

// ---------------------------------------------------------------------
// Borrowed books
// ---------------------------------------------------------------------

class BorrowedBooksNotifier extends StateNotifier<List<BorrowedBook>> {
  BorrowedBooksNotifier(this._ref) : super(MockDataService.borrowedBooks) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final api = _ref.read(apiServiceProvider);
    try {
      final studentId = _ref.read(studentProvider).id;
      final records = await api.fetchBorrowedBooks(studentId);
      state = records;
    } catch (_) {
      // keep current (demo) list
    }
  }

  /// Renews a borrow and refreshes the list so the new due date shows up.
  /// Returns an error message on failure, or null on success.
  Future<String?> renew(String borrowRecordId) async {
    final api = _ref.read(apiServiceProvider);
    try {
      await api.renewBorrowedBook(borrowRecordId);
      await refresh();
      return null;
    } catch (e) {
      return 'Could not renew this book. Please try again.';
    }
  }
}

final borrowedBooksProvider =
    StateNotifierProvider<BorrowedBooksNotifier, List<BorrowedBook>>((ref) => BorrowedBooksNotifier(ref));

// ---------------------------------------------------------------------
// Reservations
// ---------------------------------------------------------------------

class ReservationsNotifier extends StateNotifier<List<Reservation>> {
  ReservationsNotifier(this._ref) : super(MockDataService.reservations) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final api = _ref.read(apiServiceProvider);
    try {
      final studentId = _ref.read(studentProvider).id;
      final list = await api.fetchReservations(studentId);
      state = list;
    } catch (_) {
      // keep current (demo) list
    }
  }

  Future<String?> reserve(Book book) async {
    final api = _ref.read(apiServiceProvider);
    try {
      final studentId = _ref.read(studentProvider).id;
      final reservation = await api.createReservation(studentId, book.id);
      state = [reservation, ...state];
      return null;
    } catch (e) {
      return 'Could not reserve this book. Please try again.';
    }
  }

  Future<String?> cancel(String reservationId) async {
    final api = _ref.read(apiServiceProvider);
    try {
      await api.cancelReservation(reservationId);
      state = state.where((r) => r.id != reservationId).toList();
      return null;
    } catch (e) {
      return 'Could not cancel this reservation. Please try again.';
    }
  }
}

final reservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<Reservation>>((ref) => ReservationsNotifier(ref));

// ---------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------

class NotificationsNotifier extends StateNotifier<List<LibNotification>> {
  NotificationsNotifier(this._ref) : super(MockDataService.notifications) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final api = _ref.read(apiServiceProvider);
    try {
      final studentId = _ref.read(studentProvider).id;
      final list = await api.fetchNotifications(studentId);
      state = list;
    } catch (_) {
      // keep current (demo) list
    }
  }

  Future<void> markRead(String id) async {
    final api = _ref.read(apiServiceProvider);
    state = state.map((n) => n.id == id ? n.markRead() : n).toList();
    try {
      await api.markNotificationRead(id);
    } catch (_) {
      // local state already updated; backend will catch up next refresh
    }
  }

  Future<void> markAllRead() async {
    final unread = state.where((n) => !n.isRead).toList();
    state = state.map((n) => n.markRead()).toList();
    final api = _ref.read(apiServiceProvider);
    for (final n in unread) {
      try {
        await api.markNotificationRead(n.id);
      } catch (_) {
        // ignore individual failures
      }
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<LibNotification>>((ref) => NotificationsNotifier(ref));

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

// ---------------------------------------------------------------------
// Misc local-only UI state
// ---------------------------------------------------------------------

/// Wishlist (book IDs), persisted on-device with shared_preferences so it
/// survives app restarts. This is kept local-only rather than added to
/// the backend to keep the scope focused - see WishlistScreen for how
/// it's read back out.
class WishlistNotifier extends StateNotifier<Set<String>> {
  WishlistNotifier() : super(<String>{}) {
    _load();
  }

  static const _prefsKey = 'wishlist_book_ids';

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

  bool contains(String bookId) => state.contains(bookId);
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) => WishlistNotifier());

/// Books currently on the wishlist, resolved against whatever the current
/// catalog is (mock or backend-fetched) - same pattern as filteredBooksProvider.
final wishlistBooksProvider = Provider<List<Book>>((ref) {
  final ids = ref.watch(wishlistProvider);
  final all = ref.watch(allBooksProvider);
  return all.where((b) => ids.contains(b.id)).toList();
});

/// Notification preference toggles, persisted locally. These aren't wired
/// to a real push-notification system (that's a bigger project on its
/// own) but the on/off state itself is real and persists.
class NotificationPrefsNotifier extends StateNotifier<bool> {
  NotificationPrefsNotifier() : super(true) {
    _load();
  }

  static const _prefsKey = 'notifications_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, bool>((ref) => NotificationPrefsNotifier());


/// Recently viewed book IDs (most recent first)
final recentlyViewedProvider = StateProvider<List<String>>((ref) => <String>[]);

/// Bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------
// Dashboard stats - derived reactively from the notifiers above, so it
// updates automatically the moment real backend data arrives.
// ---------------------------------------------------------------------

class DashboardStats {
  final int borrowed;
  final int reserved;
  final int dueSoon;
  final double pendingFine;

  // Extended stats shown in the "Activity Dashboard" section
  final int totalBorrowedAllTime;
  final int totalReturned;
  final int overdueCount;

  const DashboardStats({
    required this.borrowed,
    required this.reserved,
    required this.dueSoon,
    required this.pendingFine,
    required this.totalBorrowedAllTime,
    required this.totalReturned,
    required this.overdueCount,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final borrowed = ref.watch(borrowedBooksProvider);
  final reserved = ref.watch(reservationsProvider);
  final issued = borrowed.where((b) => b.status == BorrowStatus.issued || b.status == BorrowStatus.overdue);
  final dueSoon = borrowed.where((b) => b.isDueSoon || b.status == BorrowStatus.overdue).length;
  final overdue = borrowed.where((b) => b.status == BorrowStatus.overdue).length;
  final returned = borrowed.where((b) => b.status == BorrowStatus.returned).length;
  final fine = borrowed.fold(0.0, (sum, b) => sum + b.fineAmount);
  return DashboardStats(
    borrowed: issued.length,
    reserved: reserved.length,
    dueSoon: dueSoon,
    pendingFine: fine,
    totalBorrowedAllTime: borrowed.length,
    totalReturned: returned,
    overdueCount: overdue,
  );
});
