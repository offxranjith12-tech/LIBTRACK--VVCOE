import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/auth/permissions.dart';
import '../../models/book_request.dart';
import '../../providers/book_request_provider.dart';
import '../../widgets/alerts_action_button.dart';
import '../../widgets/status_badge.dart';

/// Admin's inbox for student book requests. Approve verifies the student's
/// borrow limit and issues the copy in one step (reusing the same backend
/// path as the regular Issue Book flow); Reject records a reason the
/// student can see.
class BookRequestsScreen extends ConsumerStatefulWidget {
  const BookRequestsScreen({super.key});

  @override
  ConsumerState<BookRequestsScreen> createState() => _BookRequestsScreenState();
}

class _BookRequestsScreenState extends ConsumerState<BookRequestsScreen> {
  BookRequestStatus _filter = BookRequestStatus.pending;
  String? _busyId;

  Future<void> _approve(BookRequest r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve & issue?'),
        content: Text('Issue "${r.bookTitle}" to ${r.studentName} now? This checks their borrow limit automatically.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve & Issue')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = r.id);
    try {
      await ref.read(bookRequestsProvider.notifier).approve(r.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Issued "${r.bookTitle}" to ${r.studentName}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not issue: $e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(BookRequest r) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject request?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason (shown to student)', hintText: 'e.g. No copies available right now'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = r.id);
    try {
      await ref.read(bookRequestsProvider.notifier).reject(r.id, reason: controller.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reject: $e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  (String, Color) _statusChip(BookRequestStatus status) {
    switch (status) {
      case BookRequestStatus.pending:
        return ('Pending', AppColors.info);
      case BookRequestStatus.issued:
        return ('Issued', AppColors.success);
      case BookRequestStatus.rejected:
        return ('Rejected', AppColors.danger);
      case BookRequestStatus.approved:
        return ('Approved', AppColors.success);
      case BookRequestStatus.cancelled:
        return ('Cancelled', AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(bookRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Requests'),
        actions: const [AlertsActionButton(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<BookRequestStatus>(
                segments: const [
                  ButtonSegment(value: BookRequestStatus.pending, label: Text('Pending')),
                  ButtonSegment(value: BookRequestStatus.issued, label: Text('Issued')),
                  ButtonSegment(value: BookRequestStatus.rejected, label: Text('Rejected')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load requests.\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              data: (requests) {
                final filtered = requests.where((r) => r.status == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 10),
                          Text('No ${_filter.name} requests', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(bookRequestsProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = filtered[i];
                      final busy = _busyId == r.id;
                      final chip = _statusChip(r.status);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(r.bookTitle, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                StatusBadge(label: chip.$1, color: chip.$2),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${r.studentName} • ${r.department}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requested ${DateFormat('MMM d, yyyy • h:mm a').format(r.requestedAt)}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (r.status == BookRequestStatus.rejected && (r.rejectionReason ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Reason: ${r.rejectionReason}', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                            ],
                            if (r.status == BookRequestStatus.pending && Permissions.canApproveRequests(ref.watch(currentRoleProvider))) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: busy ? null : () => _reject(r),
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: busy ? null : () => _approve(r),
                                      icon: busy
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Icon(Icons.check_rounded, size: 18),
                                      label: Text(busy ? 'Issuing...' : 'Approve & Issue'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
