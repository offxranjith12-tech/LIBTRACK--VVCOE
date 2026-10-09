import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/notification_remote_service.dart';
import '../models/notification_model.dart';
import 'service_providers.dart';

LibNotification _fromRemote(RemoteNotification r) {
  return LibNotification(
    id: r.id,
    title: r.title,
    message: r.message,
    type: typeFromApiValue(r.type),
    audience: r.audience.toUpperCase() == 'ALL_STAFF'
        ? NotificationAudience.allStaff
        : r.audience.toUpperCase() == 'ALL'
            ? NotificationAudience.all
            : NotificationAudience.allStudents,
    sentOn: r.sentOn,
  );
}

/// Broadcast notifications, loaded live from `/api/v1/notifications`.
/// There is no individual/per-user target here by design.
class NotificationsNotifier extends StateNotifier<AsyncValue<List<LibNotification>>> {
  NotificationsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final NotificationRemoteService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final remote = await _service.getAll();
      state = AsyncValue.data(remote.map(_fromRemote).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> send({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationAudience audience,
  }) async {
    await _service.send(
      title: title,
      message: message,
      type: typeApiValue(type),
      audience: audienceApiValue(audience),
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await load();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<LibNotification>>>(
  (ref) => NotificationsNotifier(ref.watch(notificationRemoteServiceProvider)),
);

/// Broadcasts sent in the last 24 hours — used for the Dashboard's
/// notification badge (there's no per-user read state for broadcasts).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
  return notifications.where((n) => n.sentOn.isAfter(cutoff)).length;
});
