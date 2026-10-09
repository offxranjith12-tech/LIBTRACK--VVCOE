import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';

/// The roles LibTrack knows about. `unknown` covers the loading/error/logged-out
/// window so callers can fail closed (hide the action) instead of guessing.
enum AppRole { admin, librarian, staff, student, unknown }

AppRole _roleFromString(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'ADMIN':
      return AppRole.admin;
    case 'LIBRARIAN':
      return AppRole.librarian;
    case 'STAFF':
      return AppRole.staff;
    case 'STUDENT':
      return AppRole.student;
    default:
      return AppRole.unknown;
  }
}

/// The signed-in user's role, derived from the same `/me` profile the rest of
/// the app already loads. Reads `AppRole.unknown` while `meProfileProvider`
/// is loading or errored, so gated actions stay hidden rather than flashing
/// on before the role is known.
final currentRoleProvider = Provider<AppRole>((ref) {
  final me = ref.watch(meProfileProvider);
  return me.maybeWhen(data: (profile) => _roleFromString(profile.role), orElse: () => AppRole.unknown);
});

/// Central place for "who can do what" in the app. Every check here has a
/// matching rule in the backend's `SecurityConfig` — this file exists so the
/// UI doesn't show an action the server will reject, not as the actual
/// security boundary (that's always enforced server-side; a disabled button
/// here is a UX courtesy, never the only guard).
class Permissions {
  Permissions._();

  static bool _isStaffSide(AppRole role) => role == AppRole.admin || role == AppRole.librarian;

  /// Add / edit / delete a book, change its cover, bulk import.
  static bool canManageBooks(AppRole role) => _isStaffSide(role);
  static bool canBulkImportBooks(AppRole role) => _isStaffSide(role);

  /// Counter operations: issue / return / renew.
  static bool canIssueOrReturnBooks(AppRole role) => _isStaffSide(role);

  /// Student account CRUD (Admin or Librarian, matches backend).
  static bool canManageStudents(AppRole role) => _isStaffSide(role);

  /// Staff/Librarian account CRUD — Admin only, matches backend.
  static bool canManageStaff(AppRole role) => role == AppRole.admin;

  /// Fine collection, waiving, editing fine rules.
  static bool canManageFines(AppRole role) => _isStaffSide(role);
  static bool canWaiveFines(AppRole role) => _isStaffSide(role);

  /// Approve / reject reservations and extension requests.
  static bool canApproveRequests(AppRole role) => _isStaffSide(role);

  /// Reports & analytics (view + download).
  static bool canViewReports(AppRole role) => _isStaffSide(role);

  /// Broadcast a notification to students/staff.
  static bool canBroadcastNotifications(AppRole role) => _isStaffSide(role);

  /// Library-wide settings (hours, fine rules, borrow limits).
  static bool canEditSettings(AppRole role) => _isStaffSide(role);

  /// Audit log access — Admin only.
  static bool canViewAuditLog(AppRole role) => role == AppRole.admin;
}
