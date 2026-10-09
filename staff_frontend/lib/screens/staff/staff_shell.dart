import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_providers.dart';
import 'dashboard_screen.dart';
import 'search_books_screen.dart';
import 'my_books_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Hosts the 5 bottom-nav destinations for the Staff Module:
/// Home · Search · My Books · Alerts · Profile.
///
/// On mobile (< 600 dp wide) → BottomNavigationBar.
/// On tablet / desktop (≥ 600 dp wide) → NavigationRail on the left side.
class StaffShell extends ConsumerWidget {
  const StaffShell({super.key});

  static const _screens = [
    DashboardScreen(),
    SearchBooksScreen(),
    MyBooksScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(staffNavIndexProvider);
    final safeIndex = index.clamp(0, _screens.length - 1);
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.read).length,
      orElse: () => 0,
    );

    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      // ── Tablet / Desktop layout: NavigationRail + content side by side ──
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: safeIndex,
                onDestinationSelected: (i) =>
                    ref.read(staffNavIndexProvider.notifier).state = i,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (int i = 0; i < _screens.length; i++)
                    NavigationRailDestination(
                      icon: i == 3
                          ? Badge(
                              label: Text('$unreadCount'),
                              isLabelVisible: unreadCount > 0,
                              child: Icon(_icons[i]),
                            )
                          : Icon(_icons[i]),
                      selectedIcon: i == 3
                          ? Badge(
                              label: Text('$unreadCount'),
                              isLabelVisible: unreadCount > 0,
                              child: Icon(_selectedIcons[i]),
                            )
                          : Icon(_selectedIcons[i]),
                      label: Text(_labels[i]),
                    ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: IndexedStack(index: safeIndex, children: _screens),
              ),
            ],
          ),
        ),
      );
    }

    // ── Mobile layout: BottomNavigationBar ──
    return Scaffold(
      body: IndexedStack(index: safeIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) =>
            ref.read(staffNavIndexProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Search'),
          const NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'My Books'),
          NavigationDestination(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
