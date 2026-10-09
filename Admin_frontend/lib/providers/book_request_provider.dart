import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/book_request_remote_service.dart';
import '../models/book_request.dart';
import 'service_providers.dart';

final bookRequestRemoteServiceProvider = Provider<BookRequestRemoteService>((ref) {
  return BookRequestRemoteService(ref.watch(apiClientProvider));
});

class BookRequestsNotifier extends StateNotifier<AsyncValue<List<BookRequest>>> {
  BookRequestsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final BookRequestRemoteService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Verifies eligibility and issues the book — throws on failure (e.g. the
  /// student is over their borrow limit) so the UI can show the exact reason.
  Future<void> approve(String requestId) async {
    await _service.approve(requestId);
    await load();
  }

  Future<void> reject(String requestId, {String? reason}) async {
    await _service.reject(requestId, reason: reason);
    await load();
  }
}

final bookRequestsProvider = StateNotifierProvider<BookRequestsNotifier, AsyncValue<List<BookRequest>>>(
      (ref) => BookRequestsNotifier(ref.watch(bookRequestRemoteServiceProvider)),
);

/// Only the ones still awaiting a decision — what the badge count and the
/// default tab on the Requests screen should reflect.
final pendingBookRequestsProvider = Provider<int>((ref) {
  final requests = ref.watch(bookRequestsProvider).value ?? const [];
  return requests.where((r) => r.status == BookRequestStatus.pending).length;
});
