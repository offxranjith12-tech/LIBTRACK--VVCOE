import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/books/book_list_screen.dart';
import '../../screens/books/book_detail_screen.dart';
import '../../screens/books/add_edit_book_screen.dart';
import '../../screens/books/bulk_import_screen.dart';
import '../../screens/users/user_list_screen.dart';
import '../../screens/users/add_student_screen.dart';
import '../../screens/users/add_staff_screen.dart';
import '../../models/student.dart';
import '../../screens/transactions/issue_book_screen.dart';
import '../../screens/transactions/return_book_screen.dart';
import '../../screens/transactions/transaction_list_screen.dart';
import '../../screens/reservations/reservation_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/fines/fine_pay_screen.dart';
import '../../screens/requests/book_requests_screen.dart';
import '../../screens/notifications/notification_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const DashboardScreen()),
          GoRoute(
            path: '/books',
            builder: (context, state) => const BookListScreen(),
            routes: [
              GoRoute(path: 'add', builder: (context, state) => const AddEditBookScreen()),
              GoRoute(path: 'import', builder: (context, state) => const BulkImportBooksScreen()),
              GoRoute(path: ':id', builder: (context, state) => BookDetailScreen(bookId: state.pathParameters['id']!)),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => AddEditBookScreen(bookId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UserListScreen(),
            routes: [
              GoRoute(path: 'students/add', builder: (context, state) => const AddStudentScreen()),
              GoRoute(
                path: 'students/edit',
                builder: (context, state) => AddStudentScreen(existing: state.extra as Student?),
              ),
              GoRoute(path: 'staff/add', builder: (context, state) => const AddStaffScreen()),
              GoRoute(
                path: 'staff/edit',
                builder: (context, state) => AddStaffScreen(existing: state.extra as Staff?),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionListScreen(),
            routes: [
              GoRoute(
                path: 'issue',
                builder: (context, state) => IssueBookScreen(preselectedBookId: state.uri.queryParameters['bookId']),
              ),
              GoRoute(path: 'return', builder: (context, state) => const ReturnBookScreen()),
            ],
          ),
          GoRoute(path: '/reservations', builder: (context, state) => const ReservationScreen()),
          GoRoute(path: '/fines', builder: (context, state) => const FinePayScreen()),
          GoRoute(path: '/book-requests', builder: (context, state) => const BookRequestsScreen()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
