import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/auth/permissions.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class ReservationScreen extends ConsumerWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationsProvider);
    final pending = reservations.where((r) => r.status == ReservationStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation Management')),
      body: pending.isEmpty
          ? Center(child: Text('No pending reservations', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = pending[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.bookTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Requested by ${r.userName}', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip(Icons.format_list_numbered, 'Queue #${r.queuePosition}'),
                          const SizedBox(width: 8),
                          _chip(Icons.calendar_today_outlined, DateFormat('MMM d').format(r.reservedOn)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (Permissions.canApproveRequests(ref.watch(currentRoleProvider)))
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ref.read(reservationsProvider.notifier).reject(r.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation rejected')));
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent to user'))),
                                icon: const Icon(Icons.notifications_outlined, size: 18),
                                label: const Text('Notify'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(reservationsProvider.notifier).approve(r.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation approved')));
                                },
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
