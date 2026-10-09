import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/settings_remote_service.dart';
import '../core/network/feedback_remote_service.dart';
import '../models/transaction.dart';
import 'service_providers.dart';
import 'transaction_provider.dart';

/// Library timing + borrowing/reservation rules — editable by the admin,
/// and (via the same GET endpoint) visible to students/staff so they always
/// see the current hours and limits.
class LibrarySettingsNotifier extends StateNotifier<AsyncValue<LibrarySettingsModel>> {
  LibrarySettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final SettingsRemoteService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _service.get();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(LibrarySettingsModel settings) async {
    final saved = await _service.update(settings);
    state = AsyncValue.data(saved);
  }
}

final librarySettingsProvider = StateNotifierProvider<LibrarySettingsNotifier, AsyncValue<LibrarySettingsModel>>(
  (ref) => LibrarySettingsNotifier(ref.watch(settingsRemoteServiceProvider)),
);

/// Feedback submitted by Students/Staff — reviewed and resolved by the Admin
/// right here on the Settings screen.
class FeedbackNotifier extends StateNotifier<AsyncValue<List<FeedbackItem>>> {
  FeedbackNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final FeedbackRemoteService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resolve(String id) async {
    await _service.resolve(id);
    await load();
  }
}

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, AsyncValue<List<FeedbackItem>>>(
  (ref) => FeedbackNotifier(ref.watch(feedbackRemoteServiceProvider)),
);

/// Transactions with a pending extension request — the admin approves or
/// rejects these directly from the Settings screen; approving pushes the
/// due date out, rejecting leaves it untouched.
final pendingExtensionRequestsProvider = Provider<List<LibraryTransaction>>((ref) {
  final transactions = ref.watch(remoteTransactionsProvider).valueOrNull ?? [];
  return transactions.where((t) => t.extensionStatus == ExtensionStatus.pending).toList();
});
