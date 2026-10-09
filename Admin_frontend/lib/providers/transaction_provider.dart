import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/mock/mock_data.dart';
import '../models/transaction.dart';
import 'book_provider.dart';
import 'service_providers.dart';

class TransactionsNotifier extends StateNotifier<List<LibraryTransaction>> {
  TransactionsNotifier(this._ref) : super(List.of(MockData.transactions)) {
    _refreshOverdueStatus();
  }

  final Ref _ref;

  void _refreshOverdueStatus() {
    state = [
      for (final t in state)
        if (t.status == TransactionStatus.issued && DateTime.now().isAfter(t.dueDate))
          t.copyWith(status: TransactionStatus.overdue)
        else
          t,
    ];
  }

  LibraryTransaction issueBook({
    required String bookId,
    required String bookTitle,
    required String borrowerId,
    required String borrowerName,
    required BorrowerType borrowerType,
    int durationDays = AppConstants.defaultBorrowDurationDays,
  }) {
    final now = DateTime.now();
    final tx = LibraryTransaction(
      id: 'T${(state.length + 1).toString().padLeft(3, '0')}-${now.millisecondsSinceEpoch % 1000}',
      bookId: bookId,
      bookTitle: bookTitle,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerType: borrowerType,
      issueDate: now,
      dueDate: now.add(Duration(days: durationDays)),
      status: TransactionStatus.issued,
    );
    state = [tx, ...state];
    _ref.read(booksProvider.notifier).adjustAvailability(bookId, -1);
    return tx;
  }

  void returnBook(String transactionId, {bool collectFine = false}) {
    state = [
      for (final t in state)
        if (t.id == transactionId)
          t.copyWith(
            returnDate: DateTime.now(),
            status: TransactionStatus.returned,
            fineCollected: collectFine || t.fineAmount == 0,
          )
        else
          t,
    ];
    final tx = state.firstWhere((t) => t.id == transactionId);
    _ref.read(booksProvider.notifier).adjustAvailability(tx.bookId, 1);
  }

  void collectFine(String transactionId) {
    state = [
      for (final t in state)
        if (t.id == transactionId) t.copyWith(fineCollected: true) else t,
    ];
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<LibraryTransaction>>(
  (ref) => TransactionsNotifier(ref),
);

final activeTransactionsProvider = Provider<List<LibraryTransaction>>((ref) {
  return ref.watch(transactionsProvider).where((t) => t.status != TransactionStatus.returned).toList();
});

final overdueTransactionsProvider = Provider<List<LibraryTransaction>>((ref) {
  return ref.watch(transactionsProvider).where((t) => t.status == TransactionStatus.overdue).toList();
});

final totalFineCollectedProvider = Provider<double>((ref) {
  return ref
      .watch(transactionsProvider)
      .where((t) => t.fineCollected)
      .fold<double>(0, (sum, t) => sum + t.fineAmount);
});

/// Aggregated stats for the dashboard.
class DashboardStats {
  final int totalBooks;
  final int availableBooks;
  final int issuedBooks;
  final int totalStudents;
  final int totalStaff;
  final int reservations;
  final int overdueBooks;
  final double fineCollection;

  const DashboardStats({
    required this.totalBooks,
    required this.availableBooks,
    required this.issuedBooks,
    required this.totalStudents,
    required this.totalStaff,
    required this.reservations,
    required this.overdueBooks,
    required this.fineCollection,
  });
}

// NOTE: the mock-composed dashboard stats provider that used to live here
// has been replaced by `dashboardStatsRemoteProvider` in
// `dashboard_stats_provider.dart`, which calls the real
// `/api/v1/dashboard/stats` backend endpoint instead of aggregating local
// mock book/student/staff lists. That's what makes bulk-imported books (and
// every other real change) show up on the Dashboard immediately.

// --- Reservations ------------------------------------------------------------

class ReservationsNotifier extends StateNotifier<List<Reservation>> {
  ReservationsNotifier() : super(List.of(MockData.reservations));

  void approve(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: ReservationStatus.approved) else r,
    ];
  }

  void reject(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: ReservationStatus.rejected) else r,
    ];
  }
}

final reservationsProvider = StateNotifierProvider<ReservationsNotifier, List<Reservation>>(
  (ref) => ReservationsNotifier(),
);

// --- Real backend transactions (admin actions) ------------------------------

/// Loads the *real* transactions from `/api/v1/transactions` and exposes the
/// admin actions that are fully wired to the backend: marking a fine
/// PAID/UNPAID/WAIVED (updates the borrower's profile), manually correcting
/// a transaction's status, and approving/rejecting extension requests.
class RemoteTransactionsNotifier extends StateNotifier<AsyncValue<List<LibraryTransaction>>> {
  RemoteTransactionsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final dynamic _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Issues a book to a student/staff via the real backend. This is what
  /// makes the issue show up on the Dashboard, Transactions list, Fine Pay,
  /// and the Return Book search — they all read from this same provider.
  Future<LibraryTransaction> issueBook({
    required String bookId,
    required String borrowerId,
    required String borrowerType,
  }) async {
    final tx = await _service.issueBook(
      bookId: bookId,
      borrowerId: borrowerId,
      borrowerType: borrowerType,
    );
    await load();
    return tx;
  }

  /// Returns a book via the real backend, optionally confirming the fine
  /// (if any) was collected at the desk.
  Future<LibraryTransaction> returnBook(String transactionId, {bool fineCollected = false}) async {
    final tx = await _service.returnBook(transactionId, fineCollected: fineCollected);
    await load();
    return tx;
  }

  Future<void> updateFineStatus(String transactionId, String status, {String? paymentMethod}) async {
    await _service.updateFineStatus(transactionId, status, paymentMethod: paymentMethod);
    await load();
  }

  Future<void> manualStatusUpdate(String transactionId, String status) async {
    await _service.manualStatusUpdate(transactionId, status);
    await load();
  }

  Future<void> approveExtension(String transactionId) async {
    await _service.approveExtension(transactionId);
    await load();
  }

  Future<void> rejectExtension(String transactionId) async {
    await _service.rejectExtension(transactionId);
    await load();
  }
}

final remoteTransactionsProvider = StateNotifierProvider<RemoteTransactionsNotifier, AsyncValue<List<LibraryTransaction>>>(
  (ref) => RemoteTransactionsNotifier(ref.watch(transactionRemoteServiceProvider)),
);
