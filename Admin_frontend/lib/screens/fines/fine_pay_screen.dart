import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/auth/permissions.dart';
import '../../models/student.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/alerts_action_button.dart';
import '../../widgets/app_search_field.dart';

/// A borrower's identity info (register/staff no + department), resolved
/// from the Students/Staff directory so the Fine Pay list and search can
/// show/match on more than just the raw transaction fields.
class _BorrowerInfo {
  final String idLabel; // "Reg No" or "Staff ID"
  final String idValue;
  final String department;
  const _BorrowerInfo({required this.idLabel, required this.idValue, required this.department});
}

/// Fine Pay — search students/staff with an outstanding (unpaid) fine by
/// name, register/staff number, or department, then mark it paid once
/// collected. Reuses the same `updateFineStatus` endpoint the Transactions
/// screen already calls.
class FinePayScreen extends ConsumerStatefulWidget {
  const FinePayScreen({super.key});

  @override
  ConsumerState<FinePayScreen> createState() => _FinePayScreenState();
}

class _FinePayScreenState extends ConsumerState<FinePayScreen> {
  String _query = '';
  String? _payingId;
  FinePaymentStatus _statusFilter = FinePaymentStatus.unpaid;

  Map<String, _BorrowerInfo> _buildBorrowerLookup(WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final staff = ref.watch(staffProvider);
    final lookup = <String, _BorrowerInfo>{};
    for (final s in students) {
      lookup[s.id] = _BorrowerInfo(idLabel: 'Reg No', idValue: s.registerNumber, department: s.department);
    }
    for (final s in staff) {
      lookup[s.id] = _BorrowerInfo(idLabel: 'Staff ID', idValue: s.staffId, department: s.department);
    }
    return lookup;
  }

  Future<void> _confirmPay(LibraryTransaction t) async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark fine as paid'),
        content: Text(
          '₹${t.fineAmount.toStringAsFixed(0)} from ${t.borrowerName} for "${t.bookTitle}".\n\nHow was this fine paid?',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'OFFLINE'),
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: const Text('Offline'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'ONLINE'),
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                label: const Text('Online'),
              ),
            ],
          ),
        ],
      ),
    );
    if (method == null) return;

    setState(() => _payingId = t.id);
    try {
      await ref.read(remoteTransactionsProvider.notifier).updateFineStatus(t.id, 'PAID', paymentMethod: method);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fine marked as paid (${method == 'ONLINE' ? 'Online' : 'Offline'})')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
    } finally {
      if (mounted) setState(() => _payingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(remoteTransactionsProvider);
    final borrowerLookup = _buildBorrowerLookup(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fine Pay'),
        actions: const [AlertsActionButton(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              hintText: 'Search by name, reg no, or department...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<FinePaymentStatus>(
              segments: const [
                ButtonSegment(value: FinePaymentStatus.unpaid, label: Text('Overdue'), icon: Icon(Icons.warning_amber_rounded, size: 16)),
                ButtonSegment(value: FinePaymentStatus.paid, label: Text('Paid'), icon: Icon(Icons.check_circle_outline, size: 16)),
                ButtonSegment(value: FinePaymentStatus.waived, label: Text('Waived'), icon: Icon(Icons.remove_circle_outline, size: 16)),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (s) => setState(() => _statusFilter = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load fines.\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              data: (transactions) {
                final unpaid = transactions.where((t) => t.fineAmount > 0 && t.finePaymentStatus == _statusFilter).toList();
                final query = _query.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? unpaid
                    : unpaid.where((t) {
                        final info = borrowerLookup[t.borrowerId];
                        return t.borrowerName.toLowerCase().contains(query) ||
                            (info?.idValue.toLowerCase().contains(query) ?? false) ||
                            (info?.department.toLowerCase().contains(query) ?? false);
                      }).toList();
                filtered.sort((a, b) => b.fineAmount.compareTo(a.fineAmount));

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.currency_rupee_rounded, size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 10),
                          Text(
                            unpaid.isEmpty
                                ? (_statusFilter == FinePaymentStatus.unpaid
                                    ? 'No outstanding fines'
                                    : _statusFilter == FinePaymentStatus.paid
                                        ? 'No paid fines yet'
                                        : 'No waived fines')
                                : 'No results for "$_query"',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    final info = borrowerLookup[t.borrowerId];
                    final paying = _payingId == t.id;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: Text(
                                  t.borrowerName.isNotEmpty ? t.borrowerName[0] : '?',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.borrowerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      [
                                        if (info != null) '${info.idLabel}: ${info.idValue}',
                                        if (info != null) info.department,
                                      ].join(' • '),
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text('₹${t.fineAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${t.bookTitle}" • due ${DateFormat('MMM d, yyyy').format(t.dueDate)}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          if (_statusFilter == FinePaymentStatus.unpaid && Permissions.canManageFines(ref.watch(currentRoleProvider)))
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: paying ? null : () => _confirmPay(t),
                                icon: paying
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check_circle_outline, size: 18),
                                label: Text(paying ? 'Updating...' : 'Pay'),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (_statusFilter == FinePaymentStatus.paid ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusFilter == FinePaymentStatus.paid
                                      ? 'Paid${t.finePaymentMethod != null ? ' • ${t.finePaymentMethod == 'ONLINE' ? 'Online' : 'Offline'}' : ''}'
                                      : 'Waived',
                                  style: TextStyle(
                                    color: _statusFilter == FinePaymentStatus.paid ? AppColors.success : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
