import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: LibTrackStaffApp()));
}

class LibTrackStaffApp extends ConsumerWidget {
  const LibTrackStaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Resolve which brightness is actually showing right now (accounting
    // for ThemeMode.system) and sync AppColors.* before this frame's
    // screens build, so every AppColors.text/.textMuted/.background/.card
    // reference throughout the app reflects the correct mode.
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedBrightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => platformBrightness,
    };
    AppColors.setBrightness(resolvedBrightness);

    return MaterialApp.router(
      title: 'LibTrack — Staff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
