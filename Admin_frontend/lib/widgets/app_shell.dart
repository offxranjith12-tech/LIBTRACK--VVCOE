import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    ('/home', Icons.dashboard_rounded, 'Home'),
    ('/books', Icons.menu_book_rounded, 'Books'),
    ('/users', Icons.people_alt_rounded, 'Users'),
    ('/fines', Icons.currency_rupee_rounded, 'Fines'),
    ('/profile', Icons.person_rounded, 'Profile'),
  ];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].$1),
        backgroundColor: Theme.of(context).cardTheme.color,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$2),
              selectedIcon: Icon(tab.$2, color: AppColors.primary),
              label: tab.$3,
            ),
        ],
      ),
    );
  }
}
