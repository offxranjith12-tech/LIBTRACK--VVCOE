import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/staff_providers.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// "My Reservations" — only the logged-in staff member's own reservations
/// that are still pending: waiting in the queue, or reserved and waiting
/// to be collected. Once a copy is collected it disappears from this list.
class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  Future<void> _collect(WidgetRef ref, BuildContext context, Reservation r) async {
    try {
      await ref.read(reservationServiceProvider).collect(r.id);
      ref.invalidate(myReservationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as collected.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _cancel(WidgetRef ref, BuildContext context, Reservation r) async {
    try {
      await ref.read(reservationServiceProvider).cancel(r.id);
      ref.invalidate(myReservationsProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'My Reservations', showBack: true),
      body: reservationsAsync.when(
        data: (reservations) => reservations.isEmpty
            ? const EmptyState(icon: Icons.bookmark_border_rounded, message: 'You have no active reservations.')
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(myReservationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: reservations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _reservationCard(context, ref, reservations[i]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Could not load reservations: $e', style: const TextStyle(color: AppColors.danger))),
      ),
    );
  }

  Widget _reservationCard(BuildContext context, WidgetRef ref, Reservation r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.book.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (r.isAvailable ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  r.isAvailable ? 'Ready to Collect' : 'In Queue',
                  style: TextStyle(
                      color: r.isAvailable ? AppColors.success : AppColors.warning,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('by ${r.book.author}', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Reserved on ${r.reservedOn.day}/${r.reservedOn.month}/${r.reservedOn.year}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              if (!r.isAvailable) ...[
                const Spacer(),
                Text('Queue ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text('#${r.queuePosition}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(ref, context, r),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  label: const Text('Cancel', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: r.isAvailable ? () => _collect(ref, context, r) : null,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Collected', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
