import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'responsive.dart';

class RootScaffold extends ConsumerWidget {
  final Widget child;
  const RootScaffold({super.key, required this.child});

  static const _routes = ['/dashboard', '/search', '/my-books', '/notifications', '/profile'];
  static const _labels = ['Home', 'Search', 'My Books', 'Alerts', 'Profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.search_outlined,
    Icons.menu_book_outlined,
    Icons.notifications_outlined,
    Icons.person_outline_rounded,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.menu_book_rounded,
    Icons.notifications_rounded,
    Icons.person_rounded,
  ];

  int _indexForLocation(String location) {
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    final unread = ref.watch(unreadNotificationCountProvider);

    // On tablets and laptops there's plenty of horizontal room, so we
    // switch from a bottom navigation bar to a side navigation rail —
    // this both looks better and reclaims vertical space for content.
    final useRail = Breakpoints.isTablet(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => context.go(_routes[i]),
              backgroundColor: Theme.of(context).cardColor,
              labelType: NavigationRailLabelType.all,
              leading: const SizedBox(height: 12),
              selectedIconTheme: const IconThemeData(color: AppColors.primaryRed),
              selectedLabelTextStyle: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
              destinations: [
                for (int i = 0; i < _routes.length; i++)
                  NavigationRailDestination(
                    icon: i == 3
                        ? Badge(label: Text('$unread'), isLabelVisible: unread > 0, child: Icon(_icons[i]))
                        : Icon(_icons[i]),
                    selectedIcon: Icon(_selectedIcons[i]),
                    label: Text(_labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_routes[i]),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Search'),
          const NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'My Books'),
          NavigationDestination(
            icon: Badge(
              label: Text('$unread'),
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
