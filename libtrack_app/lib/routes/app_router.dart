import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/book_details/book_details_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/my_books/my_books_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/feedback_screen.dart';
import '../screens/profile/help_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/wishlist_screen.dart';
import '../screens/reserved_books/reserved_books_screen.dart';
import '../screens/search/search_screen.dart';
import '../widgets/root_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app's router. [initialLocation] is decided once at startup
/// in main.dart based on whether a login token is already stored, so a
/// returning user skips straight past the login screen.
GoRouter createRouter(String initialLocation) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => RootScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/my-books',
            pageBuilder: (context, state) => const NoTransitionPage(child: MyBooksScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/book/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => BookDetailsScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reserved-books',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReservedBooksScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/change-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/help',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
  );
}
