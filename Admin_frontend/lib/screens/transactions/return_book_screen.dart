import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/pdf_service.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';

class ReturnBookScreen extends ConsumerStatefulWidget {
  const ReturnBookScreen({super.key});

  @override
  ConsumerState<ReturnBookScreen> createState() => _ReturnBookScreenState();
}

class _ReturnBookScreenState extends ConsumerState<ReturnBookScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedId;
  bool _fineCollected = false;
  bool _returning = false;

  Map<String, String> _buildIdLookup(WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final staff = ref.watch(staffProvider);
    final lookup = <String, String>{};
    for (final s in students) {
      lookup[s.id] = s.registerNumber;
    }
    for (final s in staff) {
      lookup[s.id] = s.staffId;
    }
    return lookup;
  }

  Future<void> _confirmReturn(LibraryTransaction t) async {
    setState(() => _returning = true);
    try {
      await ref.read(remoteTransactionsProvider.notifier).returnBook(t.id, fineCollected: _fineCollected);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.check_circle, color: AppColors.success), SizedBox(width: 10), Text('Book Returned')]),
          content: Text('${t.bookTitle} has been marked as returned.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
      if (mounted) {
        setState(() {
          _selectedId = null;
          _fineCollected = false;
          _searchController.clear();
          _query = '';
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not return book: $e')));
    } finally {
      if (mounted) setState(() => _returning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(remoteTransactionsProvider);

    return transactionsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Return Book')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Return Book')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('Could not load active issues.\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
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
      ),
      data: (transactions) {
        final idLookup = _buildIdLookup(ref);
        final active = transactions.where((tx) => tx.status == TransactionStatus.issued || tx.status == TransactionStatus.overdue).toList();

        final query = _query.trim().toLowerCase();
        final matches = query.isEmpty
            ? <LibraryTransaction>[]
            : active.where((tx) {
                final mappedId = (idLookup[tx.borrowerId] ?? '').toLowerCase();
                return tx.borrowerId.toLowerCase() == query ||
                    mappedId == query ||
                    mappedId.contains(query) ||
                    tx.borrowerName.toLowerCase().contains(query) ||
                    tx.bookTitle.toLowerCase().contains(query);
              }).toList();

        LibraryTransaction? selected;
        if (_selectedId != null) {
          final found = active.where((tx) => tx.id == _selectedId).toList();
          selected = found.isNotEmpty ? found.first : null;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Return Book')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {
                  _query = v;
                  _selectedId = null;
                  _fineCollected = false;
                }),
                decoration: const InputDecoration(
                  hintText: 'Search by Register/Staff No, Name, or Book Title',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              if (selected == null && query.isNotEmpty && matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No active issue found for "$_query"', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else if (selected == null && matches.isNotEmpty)
                ...matches.map(
                  (m) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text(m.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${m.borrowerName} • due ${DateFormat('MMM d, yyyy').format(m.dueDate)}'),
                      trailing: m.overdueDays > 0
                          ? Text('${m.overdueDays}d overdue', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12))
                          : null,
                      onTap: () => setState(() => _selectedId = m.id),
                    ),
                  ),
                )
              else if (selected == null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_return_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Search for an active issue to return', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(selected.bookTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                          TextButton(onPressed: () => setState(() => _selectedId = null), child: const Text('Change')),
                        ],
                      ),
                      Text('Borrowed by ${selected.borrowerName}', style: TextStyle(color: AppColors.textSecondary)),
                      const Divider(height: 24),
                      _row('Issue Date', DateFormat('MMM d, yyyy').format(selected.issueDate)),
                      _row('Due Date', DateFormat('MMM d, yyyy').format(selected.dueDate)),
                      _row('Overdue Days', '${selected.overdueDays} days', valueColor: selected.overdueDays > 0 ? AppColors.danger : AppColors.success),
                      _row('Fine Amount', '₹${selected.fineAmount.toStringAsFixed(0)}', valueColor: selected.fineAmount > 0 ? AppColors.danger : AppColors.success),
                    ],
                  ),
                ),
                if (selected.fineAmount > 0) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _fineCollected,
                    onChanged: (v) => setState(() => _fineCollected = v ?? false),
                    title: const Text('Fine collected'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                ],
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: selected == null ? null : () => PdfService.printReceipt(selected!),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Receipt'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (selected == null || _returning) ? null : () => _confirmReturn(selected!),
                      icon: _returning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_returning ? 'Returning...' : 'Return Book'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor ?? AppColors.text)),
        ],
      ),
    );
  }
}
