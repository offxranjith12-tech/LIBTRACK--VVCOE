import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Settings', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDark,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v ? ThemeMode.dark : ThemeMode.light),
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Switch between light and dark appearance', style: TextStyle(fontSize: 12)),
                  activeThumbColor: AppColors.primary,
                  secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary),
                ),
                Divider(height: 1, color: AppColors.divider),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
                  title: const Text('Match system setting', style: TextStyle(fontSize: 13.5)),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Library'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: ListTile(
              leading: const Icon(Icons.schedule_outlined, color: AppColors.primary),
              title: const Text('Library Timings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('View opening hours for each day', style: TextStyle(fontSize: 12)),
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () => context.push('/library-timings'),
            ),
          ),
        ],
      ),
    );
  }
}
