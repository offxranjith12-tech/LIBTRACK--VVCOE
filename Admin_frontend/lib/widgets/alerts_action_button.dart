import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';

/// The bell-with-badge "Alerts" button shown at the top of every main
/// screen (Dashboard, Books, Users, Reports, ...). Tapping it opens
/// `/notifications`.
class AlertsActionButton extends ConsumerWidget {
  final Color? backgroundColor;
  final Color? iconColor;

  const AlertsActionButton({super.key, this.backgroundColor, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: backgroundColor ?? AppColors.card),
          onPressed: () => context.push('/notifications'),
          icon: Icon(Icons.notifications_outlined, color: iconColor ?? AppColors.text),
          tooltip: 'Alerts',
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}
