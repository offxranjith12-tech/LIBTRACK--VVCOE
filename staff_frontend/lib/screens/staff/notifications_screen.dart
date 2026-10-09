import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Notifications tab — shows all notifications for the logged-in staff member.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType t) {
    switch (t) {
      case NotificationType.dueDate:
        return Icons.schedule_rounded;
      case NotificationType.reservation:
        return Icons.bookmark_added_outlined;
      case NotificationType.overdue:
        return Icons.warning_amber_rounded;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.newArrival:
        return Icons.new_releases_outlined;
    }
  }

  Color _colorFor(NotificationType t) {
    switch (t) {
      case NotificationType.dueDate:
        return AppColors.warning;
      case NotificationType.reservation:
        return AppColors.secondary;
      case NotificationType.overdue:
        return AppColors.danger;
      case NotificationType.announcement:
        return AppColors.primary;
      case NotificationType.newArrival:
        return AppColors.success;
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: notificationsAsync.when(
              data: (notifications) => notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      message: 'You\'re all caught up!')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          ref.invalidate(notificationsProvider),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                            isWide ? 28 : 20, 12, isWide ? 28 : 20, 24),
                        children: notifications
                            .map((n) => GestureDetector(
                                  onTap: () async {
                                    if (!n.read) {
                                      await ref
                                          .read(notificationServiceProvider)
                                          .markRead(n.id);
                                      ref.invalidate(notificationsProvider);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: n.read
                                          ? AppColors.card
                                          : _colorFor(n.type)
                                              .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.card),
                                      boxShadow: AppShadows.soft,
                                      border: n.read
                                          ? null
                                          : Border.all(
                                              color: _colorFor(n.type)
                                                  .withValues(alpha: 0.35),
                                              width: 1.2),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _colorFor(n.type)
                                                .withValues(
                                                    alpha: n.read ? 0.1 : 0.18),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(_iconFor(n.type),
                                              color: _colorFor(n.type),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      n.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: n.read
                                                            ? FontWeight.w600
                                                            : FontWeight.w800,
                                                        fontSize: 13.5,
                                                        color: n.read
                                                            ? AppColors.textMuted
                                                            : AppColors.text,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!n.read)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                          color:
                                                              _colorFor(n.type),
                                                          shape:
                                                              BoxShape.circle),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                n.message,
                                                style: TextStyle(
                                                  color: n.read
                                                      ? AppColors.textMuted
                                                      : AppColors.text
                                                          .withValues(alpha: 0.85),
                                                  fontSize: 12.5,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(_timeAgo(n.time),
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                  child: Text('Could not load notifications: $e',
                      style: const TextStyle(color: AppColors.danger))),
            ),
          ),
        ),
      ),
    );
  }
}
