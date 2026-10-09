import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/auth/permissions.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

/// Broadcast-only notifications — there is intentionally no "Individual"
/// option here. Every notification goes out to a whole audience (All
/// Students / All Staff / Everyone), sent and stored live via the backend.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final canBroadcast = Permissions.canBroadcastNotifications(ref.watch(currentRoleProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      floatingActionButton: !canBroadcast
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showComposeSheet(context, ref),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Send New'),
            ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('Could not load notifications.\n$err', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(notificationsProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(child: Text('No notifications sent yet', style: TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: canBroadcast ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                  onDismissed: (_) => ref.read(notificationsProvider.notifier).delete(n.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _iconColor(n.type).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconFor(n.type), color: _iconColor(n.type), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(n.message, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(
                                '${n.typeLabel} • ${n.audienceLabel} • ${DateFormat('MMM d, h:mm a').format(n.sentOn)}',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.dueReminder:
        return Icons.schedule_rounded;
      case NotificationType.newArrival:
        return Icons.auto_awesome_rounded;
      case NotificationType.holiday:
        return Icons.event_busy_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.fineReminder:
        return Icons.currency_rupee_rounded;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.dueReminder:
        return AppColors.warning;
      case NotificationType.newArrival:
        return AppColors.info;
      case NotificationType.holiday:
        return const Color(0xFF6A1B9A);
      case NotificationType.announcement:
        return AppColors.primary;
      case NotificationType.fineReminder:
        return AppColors.danger;
    }
  }

  void _showComposeSheet(BuildContext context, WidgetRef ref) {
    NotificationAudience audience = NotificationAudience.allStudents;
    NotificationType type = NotificationType.announcement;
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Send Notification', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Broadcast only — this goes out to a whole audience, not an individual person.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Text('Send To', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(label: const Text('All Students'), selected: audience == NotificationAudience.allStudents, onSelected: (_) => setState(() => audience = NotificationAudience.allStudents)),
                        ChoiceChip(label: const Text('All Staff'), selected: audience == NotificationAudience.allStaff, onSelected: (_) => setState(() => audience = NotificationAudience.allStaff)),
                        ChoiceChip(label: const Text('Everyone'), selected: audience == NotificationAudience.all, onSelected: (_) => setState(() => audience = NotificationAudience.all)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Notification Type', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<NotificationType>(
                      initialValue: type,
                      items: const [
                        DropdownMenuItem(value: NotificationType.dueReminder, child: Text('Due Reminder')),
                        DropdownMenuItem(value: NotificationType.newArrival, child: Text('New Arrivals')),
                        DropdownMenuItem(value: NotificationType.holiday, child: Text('Holiday Notice')),
                        DropdownMenuItem(value: NotificationType.announcement, child: Text('Library Announcement')),
                        DropdownMenuItem(value: NotificationType.fineReminder, child: Text('Fine Reminder')),
                      ],
                      onChanged: (v) => setState(() => type = v!),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title')),
                    const SizedBox(height: 12),
                    TextField(controller: messageController, maxLines: 3, decoration: const InputDecoration(hintText: 'Message')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: sending
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) return;
                              setState(() => sending = true);
                              try {
                                await ref.read(notificationsProvider.notifier).send(
                                      title: titleController.text.trim(),
                                      message: messageController.text.trim(),
                                      type: type,
                                      audience: audience,
                                    );
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                setState(() => sending = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send: $e')));
                                }
                              }
                            },
                      child: sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Send Notification'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
