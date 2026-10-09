import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/staff_providers.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Lets a staff member reserve a book for themselves. If a copy is free
/// right now it's held immediately, ready to collect at the counter. If
/// every copy is currently out, the staff member joins the reservation
/// queue instead — with priority ahead of student reservations — and is
/// notified automatically once a copy becomes available.
class JoinQueueScreen extends ConsumerStatefulWidget {
  final Book book;
  const JoinQueueScreen({super.key, required this.book});

  @override
  ConsumerState<JoinQueueScreen> createState() => _JoinQueueScreenState();
}

class _JoinQueueScreenState extends ConsumerState<JoinQueueScreen> {
  bool _submitting = false;
  String? _error;
  Reservation? _created;

  bool get _bookIsFree => widget.book.availableCopies > 0;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final reservation = await ref.read(reservationServiceProvider).reserveForSelf(widget.book.id);
      ref.invalidate(myReservationsProvider);
      ref.invalidate(allBooksProvider);
      ref.invalidate(filteredBooksProvider);
      setState(() => _created = reservation);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) return _confirmationView(context, _created!);

    return Scaffold(
      appBar: GlassAppBar(title: _bookIsFree ? 'Reserve Book' : 'Join Queue', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.book.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text('${widget.book.availableCopies}/${widget.book.totalCopies} copies available',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_bookIsFree ? AppColors.success : AppColors.warning).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: (_bookIsFree ? AppColors.success : AppColors.warning).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(_bookIsFree ? Icons.check_circle_outline_rounded : Icons.hourglass_bottom_rounded,
                    color: _bookIsFree ? AppColors.success : AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _bookIsFree
                        ? 'A copy is available. Reserving will send a request to the admin for approval. You will receive a notification once accepted.'
                        : 'All copies are currently checked out. You\'ll join the queue and get priority over student reservations - you\'ll be notified the moment a copy is free.',
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(_bookIsFree ? 'Confirm Reservation' : 'Confirm Queue Join'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmationView(BuildContext context, Reservation reservation) {
    final available = reservation.isAvailable;
    return Scaffold(
      appBar: GlassAppBar(title: available ? 'Book Reserved' : 'Queue Joined', showBack: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  available ? Icons.check_circle_rounded : Icons.bookmark_added_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(height: 14),
                Text(
                  available ? 'Successfully Reserved' : 'Successfully Added to Queue',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(reservation.book.title, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('by ${reservation.book.author}',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                const SizedBox(height: 14),
                if (available)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Text('Reservation requested. Wait for admin approval.',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success, fontSize: 12.5)),
                  )
                else
                  Text('Queue position: #${reservation.queuePosition}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 10),
                Text(
                  available
                      ? 'You will receive a notification once the admin accepts your request.'
                      : 'You\'ll be notified automatically when a copy becomes available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
