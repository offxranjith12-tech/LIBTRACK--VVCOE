import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/status_badge.dart';

/// Real backend transaction ledger. Every row supports the admin's manual
/// controls: mark the fine PAID / UNPAID / WAIVED (updates the borrower's
/// profile), manually correct the status (e.g. a desk return that wasn't
/// scanned), and approve/reject a pending extension request.
class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(remoteTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.output_rounded), tooltip: 'Issue', onPressed: () => context.push('/transactions/issue')),
          IconButton(icon: const Icon(Icons.input_rounded), tooltip: 'Return', onPressed: () => context.push('/transactions/return')),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('Could not load transactions.\n$err', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(remoteTransactionsProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(child: Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(remoteTransactionsProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TransactionCard(transaction: transactions[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final LibraryTransaction transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final (label, color) = switch (t.status) {
      TransactionStatus.issued => ('Issued', AppColors.issued),
      TransactionStatus.returned => ('Returned', AppColors.success),
      TransactionStatus.overdue => ('Overdue', AppColors.danger),
      TransactionStatus.lost => ('Lost', AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.bookTitle, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              StatusBadge(label: label, color: color),
              PopupMenuButton<String>(
                onSelected: (v) => _handleAction(context, ref, v),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'status_issued', child: Text('Set status: Issued')),
                  const PopupMenuItem(value: 'status_returned', child: Text('Set status: Returned')),
                  const PopupMenuItem(value: 'status_overdue', child: Text('Set status: Overdue')),
                  const PopupMenuItem(value: 'status_lost', child: Text('Set status: Lost')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'fine_paid', child: Text('Mark fine: Paid')),
                  const PopupMenuItem(value: 'fine_unpaid', child: Text('Mark fine: Unpaid')),
                  const PopupMenuItem(value: 'fine_waived', child: Text('Mark fine: Waived')),
                  if (t.extensionStatus == ExtensionStatus.pending) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'extension_approve', child: Text('Approve extension request')),
                    const PopupMenuItem(value: 'extension_reject', child: Text('Reject extension request')),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${t.borrowerName} • ${t.borrowerType == BorrowerType.student ? "Student" : "Staff"}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text('Due: ${DateFormat('MMM d, yyyy').format(t.dueDate)}', style: const TextStyle(fontSize: 12)),
          if (t.extensionStatus == ExtensionStatus.pending && t.requestedDueDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Extension requested → ${DateFormat('MMM d, yyyy').format(t.requestedDueDate!)}',
                style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          if (t.fineAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Fine: ₹${t.fineAmount.toStringAsFixed(0)} (${_fineStatusLabel(t.finePaymentStatus)})',
                style: TextStyle(fontSize: 12, color: t.finePaymentStatus == FinePaymentStatus.unpaid ? AppColors.danger : AppColors.success),
              ),
            ),
        ],
      ),
    );
  }

  String _fineStatusLabel(FinePaymentStatus status) {
    switch (status) {
      case FinePaymentStatus.paid:
        return 'paid';
      case FinePaymentStatus.waived:
        return 'waived';
      case FinePaymentStatus.unpaid:
        return 'pending';
    }
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final notifier = ref.read(remoteTransactionsProvider.notifier);
    try {
      switch (action) {
        case 'status_issued':
          await notifier.manualStatusUpdate(transaction.id, 'ISSUED');
          break;
        case 'status_returned':
          await notifier.manualStatusUpdate(transaction.id, 'RETURNED');
          break;
        case 'status_overdue':
          await notifier.manualStatusUpdate(transaction.id, 'OVERDUE');
          break;
        case 'status_lost':
          await notifier.manualStatusUpdate(transaction.id, 'LOST');
          break;
        case 'fine_paid':
          await notifier.updateFineStatus(transaction.id, 'PAID');
          break;
        case 'fine_unpaid':
          await notifier.updateFineStatus(transaction.id, 'UNPAID');
          break;
        case 'fine_waived':
          await notifier.updateFineStatus(transaction.id, 'WAIVED');
          break;
        case 'extension_approve':
          await notifier.approveExtension(transaction.id);
          break;
        case 'extension_reject':
          await notifier.rejectExtension(transaction.id);
          break;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }
}
