import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ResponsiveCenter(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primaryRed),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryRed),
                    title: const Text('Due Date & Reservation Alerts'),
                    subtitle: const Text('Get notified about due dates, fines, and reservation updates'),
                    value: notificationsEnabled,
                    onChanged: (v) => ref.read(notificationPrefsProvider.notifier).setEnabled(v),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Account', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryRed),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textGrey),
                        onTap: () => context.push('/settings/change-password'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                        title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(apiServiceProvider).logout();
    if (!context.mounted) return;
    context.go('/login');
  }
}
