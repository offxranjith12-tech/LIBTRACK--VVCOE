import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/book.dart';
import '../../models/student.dart';
import '../../models/transaction.dart';
import '../../providers/service_providers.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';

class IssueBookScreen extends ConsumerStatefulWidget {
  final String? preselectedBookId;
  const IssueBookScreen({super.key, this.preselectedBookId});

  @override
  ConsumerState<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends ConsumerState<IssueBookScreen> {
  BorrowerType _borrowerType = BorrowerType.student;
  dynamic _selectedUser;
  Book? _selectedBook;
  final _userIdController = TextEditingController();
  final _bookSearchController = TextEditingController();
  final DateTime _issueDate = DateTime.now();
  late DateTime _dueDate;

  List<Book> _bookResults = [];
  bool _searchingBooks = false;
  bool _issuing = false;
  Timer? _bookDebounce;

  @override
  void initState() {
    super.initState();
    _dueDate = _issueDate.add(const Duration(days: AppConstants.defaultBorrowDurationDays));
    if (widget.preselectedBookId != null) {
      _loadPreselectedBook(widget.preselectedBookId!);
    }
  }

  @override
  void dispose() {
    _bookDebounce?.cancel();
    _userIdController.dispose();
    _bookSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreselectedBook(String id) async {
    try {
      final book = await ref.read(bookRemoteServiceProvider).getById(id);
      if (mounted) {
        setState(() {
          _selectedBook = book;
          _bookSearchController.text = book.title;
        });
      }
    } catch (_) {
      // Book may no longer exist — leave selection empty, admin can search again.
    }
  }

  void _searchUser(String query) {
    if (query.trim().isEmpty) {
      setState(() => _selectedUser = null);
      return;
    }
    if (_borrowerType == BorrowerType.student) {
      final students = ref.read(studentsProvider);
      final match = students.where((s) => s.registerNumber.toLowerCase() == query.toLowerCase()).toList();
      setState(() => _selectedUser = match.isNotEmpty ? match.first : null);
    } else {
      final staff = ref.read(staffProvider);
      final match = staff.where((s) => s.staffId.toLowerCase() == query.toLowerCase()).toList();
      setState(() => _selectedUser = match.isNotEmpty ? match.first : null);
    }
  }

  void _searchBooks(String query) {
    _bookDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _bookResults = []);
      return;
    }
    _bookDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searchingBooks = true);
      try {
        final result = await ref.read(bookRemoteServiceProvider).search(
              query: query,
              onlyAvailable: true,
              page: 0,
              size: 10,
            );
        if (mounted) setState(() => _bookResults = result.books);
      } catch (_) {
        if (mounted) setState(() => _bookResults = []);
      } finally {
        if (mounted) setState(() => _searchingBooks = false);
      }
    });
  }

  bool get _canIssue {
    if (_selectedUser == null || _selectedBook == null) return false;
    if (_selectedBook!.availableCopies <= 0) return false;
    final canBorrow = _selectedUser is Student ? (_selectedUser as Student).canBorrow : (_selectedUser as Staff).canBorrow;
    return canBorrow;
  }

  Future<void> _confirmIssue() async {
    final book = _selectedBook!;
    final user = _selectedUser;
    final name = user is Student ? user.name : (user as Staff).name;
    final id = user is Student ? user.id : (user as Staff).id;

    setState(() => _issuing = true);
    try {
      await ref.read(remoteTransactionsProvider.notifier).issueBook(
            bookId: book.id,
            borrowerId: id,
            borrowerType: _borrowerType == BorrowerType.student ? 'STUDENT' : 'STAFF',
          );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.check_circle, color: AppColors.success), SizedBox(width: 10), Text('Book Issued')]),
          content: Text('${book.title} has been issued to $name.\nDue: ${DateFormat('MMM d, yyyy').format(_dueDate)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not issue book: $e')));
      }
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowLimit = _selectedUser is Student
        ? (_selectedUser as Student).borrowLimit
        : _selectedUser is Staff
            ? (_selectedUser as Staff).borrowLimit
            : null;
    final borrowedCount = _selectedUser is Student
        ? (_selectedUser as Student).borrowedBooksCount
        : _selectedUser is Staff
            ? (_selectedUser as Staff).borrowedBooksCount
            : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Book')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          SegmentedButton<BorrowerType>(
            segments: const [
              ButtonSegment(value: BorrowerType.student, label: Text('Student ID'), icon: Icon(Icons.school_outlined)),
              ButtonSegment(value: BorrowerType.staff, label: Text('Staff ID'), icon: Icon(Icons.badge_outlined)),
            ],
            selected: {_borrowerType},
            onSelectionChanged: (s) => setState(() {
              _borrowerType = s.first;
              _selectedUser = null;
              _userIdController.clear();
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userIdController,
            onChanged: _searchUser,
            decoration: InputDecoration(
              hintText: _borrowerType == BorrowerType.student ? 'Enter Register Number (e.g. 21CSE045)' : 'Enter Staff ID',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedUser != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedUser is Student ? (_selectedUser as Student).name : (_selectedUser as Staff).name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Borrow limit: $borrowedCount / $borrowLimit', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!_canIssue && _selectedBook != null)
                    const Icon(Icons.error_outline, color: AppColors.danger),
                ],
              ),
            )
          else if (_userIdController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No matching user found', style: TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          const SizedBox(height: 20),
          const Text('Select Book', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_selectedBook != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedBook!.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${_selectedBook!.availableCopies} available', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedBook = null;
                      _bookSearchController.clear();
                      _bookResults = [];
                    }),
                    child: const Text('Change'),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _bookSearchController,
              onChanged: _searchBooks,
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN',
                prefixIcon: const Icon(Icons.menu_book_outlined),
                suffixIcon: _searchingBooks
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
            ),
            if (_bookResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _bookResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = _bookResults[i];
                    return ListTile(
                      dense: true,
                      title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${b.author} • ${b.availableCopies} avail.', maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => setState(() {
                        _selectedBook = b;
                        _bookResults = [];
                        _bookSearchController.text = b.title;
                      }),
                    );
                  },
                ),
              )
            else if (_bookSearchController.text.isNotEmpty && !_searchingBooks)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('No available books found', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Issue Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d, yyyy').format(_issueDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Due Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d, yyyy').format(_dueDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_canIssue && !_issuing) ? _confirmIssue : null,
              icon: _issuing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_issuing ? 'Issuing...' : 'Confirm Issue'),
            ),
          ),
        ),
      ),
    );
  }
}
