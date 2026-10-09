import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/staff_providers.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/staff/book_details_screen.dart';
import '../screens/staff/change_password_screen.dart';
import '../screens/staff/contact_librarian_screen.dart';
import '../screens/staff/edit_profile_screen.dart';
import '../screens/staff/feedback_screen.dart';
import '../screens/staff/help_support_screen.dart';
import '../screens/staff/join_queue_screen.dart';
import '../screens/staff/library_rules_screen.dart';
import '../screens/staff/library_timings_screen.dart';
import '../screens/staff/notifications_screen.dart';
import '../screens/staff/recently_viewed_screen.dart';
import '../screens/staff/reservations_screen.dart';
import '../screens/staff/saved_books_screen.dart';
import '../screens/staff/settings_screen.dart';
import '../theme/app_theme.dart';

/// Central GoRouter setup. `/` is [AuthGate], which shows the login screen
/// or the bottom-nav [StaffShell] depending on whether a JWT is cached.
/// Every other screen is pushed on top as a full route so it gets its own
/// back button and transition.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return _BookDetailsLoader(bookId: id);
      },
    ),
    GoRoute(
      path: '/reservations',
      builder: (context, state) => const ReservationsScreen(),
    ),
    GoRoute(
      path: '/join-queue',
      builder: (context, state) {
        final book = state.extra as Book;
        return JoinQueueScreen(book: book);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) {
        final staff = state.extra as Staff;
        return EditProfileScreen(staff: staff);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/library-timings',
      builder: (context, state) => const LibraryTimingsScreen(),
    ),
    GoRoute(
      path: '/library-rules',
      builder: (context, state) => const LibraryRulesScreen(),
    ),
    GoRoute(
      path: '/contact-librarian',
      builder: (context, state) => const ContactLibrarianScreen(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const SavedBooksScreen(),
    ),
    GoRoute(
      path: '/recently-viewed',
      builder: (context, state) => const RecentlyViewedScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpSupportScreen(),
    ),
  ],
);

/// Fetches the book from the backend before handing it to BookDetailsScreen,
/// which expects a fully-loaded [Book].
class _BookDetailsLoader extends ConsumerWidget {
  final String bookId;
  const _BookDetailsLoader({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailsProvider(bookId));
    return bookAsync.when(
      data: (book) => BookDetailsScreen(book: book),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('Could not load book: $e'))),
    );
  }
}
