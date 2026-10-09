import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_providers.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip straight to the dashboard if the user is already logged in
  // (a token is already stored from a previous session).
  final hasToken = await ApiService().hasStoredToken();
  final router = createRouter(hasToken ? '/dashboard' : '/login');

  runApp(ProviderScope(child: LibTrackApp(router: router)));
}

class LibTrackApp extends ConsumerWidget {
  final GoRouter router;
  const LibTrackApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'LibTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
