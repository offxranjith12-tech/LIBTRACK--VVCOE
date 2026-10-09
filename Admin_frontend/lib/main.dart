import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore any previously-saved server URL (see Login screen's "Server
  // Connection" sheet / Settings) before the app makes its first request.
  await ApiClient.instance.init();
  runApp(const ProviderScope(child: LibTrackAdminApp()));
}

class LibTrackAdminApp extends ConsumerWidget {
  const LibTrackAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Resolve the *effective* brightness (accounting for ThemeMode.system)
    // and stamp it onto AppColors before anything below builds. Every
    // screen's cards/text/dividers read AppColors.card/.text/.textSecondary
    // etc as dynamic getters, so this one flag flip is what makes Dark Mode
    // apply everywhere in the app, not just the Scaffold background.
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final effectiveIsDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    AppColors.isDark = effectiveIsDark;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // Some phones ship with a large system font-size (accessibility)
      // setting that, combined with fixed-height rows like the filter chip
      // bar, used to trigger a RenderFlex "overflow" banner (the black/
      // yellow striped glitch) on-device even though everything looked
      // fine on a dev machine at 1.0x scale. Clamping keeps every screen's
      // hand-tuned layouts intact while still growing text somewhat for
      // users who need it.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child!,
        );
      },
    );
  }
}
