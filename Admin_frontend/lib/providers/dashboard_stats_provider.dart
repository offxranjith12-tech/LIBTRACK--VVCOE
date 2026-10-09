import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import 'service_providers.dart';
import 'transaction_provider.dart' show DashboardStats, reservationsProvider;

/// Real, live dashboard stats pulled from `/api/v1/dashboard/stats` — the
/// backend already aggregates books/students/staff/overdue/fine counts
/// straight from MySQL, so bulk imports and every other change show up
/// immediately instead of the stale numbers the old mock-based version showed.
///
/// `autoDispose` is intentional: leaving the Dashboard tab and coming back
/// re-fetches fresh numbers rather than showing whatever was cached from
/// the last visit, so an admin doesn't have to manually pull-to-refresh
/// just to see a bulk import reflected.
final dashboardStatsRemoteProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final service = ref.watch(dashboardRemoteServiceProvider);
  final stats = await service.getStats();

  // Reservations have no backend support yet in this build, so that one
  // field still comes from the in-memory reservations list — everything
  // else below is real.
  final reservations = ref.watch(reservationsProvider);

  int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  return DashboardStats(
    totalBooks: asInt(stats['totalBooks']),
    availableBooks: asInt(stats['availableBooks']),
    issuedBooks: asInt(stats['issuedBooks']),
    totalStudents: asInt(stats['totalStudents']),
    totalStaff: asInt(stats['totalStaff']),
    reservations: reservations.where((r) => r.status == ReservationStatus.pending).length,
    overdueBooks: asInt(stats['overdueBooks']),
    fineCollection: asDouble(stats['fineCollection']),
  );
});
