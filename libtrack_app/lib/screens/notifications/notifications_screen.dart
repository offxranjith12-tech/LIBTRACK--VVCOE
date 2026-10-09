import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/notification_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  (IconData, Color) _meta(NotificationType type) {
    switch (type) {
      case NotificationType.dueReminder:
        return (Icons.access_time_filled_rounded, AppColors.warning);
      case NotificationType.reservationApproved:
        return (Icons.check_circle_rounded, AppColors.success);
      case NotificationType.newArrival:
        return (Icons.fiber_new_rounded, const Color(0xFF1565C0));
      case NotificationType.fineReminder:
        return (Icons.currency_rupee_rounded, AppColors.danger);
      case NotificationType.announcement:
        return (Icons.campaign_rounded, AppColors.primaryRed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final df = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text('No notifications', style: Theme.of(context).textTheme.bodyMedium))
          : ResponsiveCenter(
              padding: EdgeInsets.zero,
              child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final (icon, color) = _meta(n.type);
                return SoftCard(
                  color: n.isRead ? null : AppColors.surfaceLight,
                  onTap: () => ref.read(notificationsProvider.notifier).markRead(n.id),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(n.message, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 6),
                            Text(df.format(n.timestamp), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5)),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
            ),
    );
  }
}
