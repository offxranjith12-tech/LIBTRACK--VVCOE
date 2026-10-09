import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/auth/permissions.dart';
import '../../core/network/settings_remote_service.dart';
import '../../core/network/feedback_remote_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/server_connection_sheet.dart';

/// System Settings — library timing + borrowing/reservation rules are real,
/// backend-backed values (visible to Students/Staff too, editable only here
/// by the Admin), plus a Feedback inbox and pending extension-request queue.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final settingsAsync = ref.watch(librarySettingsProvider);
    final feedbackAsync = ref.watch(feedbackProvider);
    final pendingExtensions = ref.watch(pendingExtensionRequestsProvider);
    final role = ref.watch(currentRoleProvider);
    final canEditSettings = Permissions.canEditSettings(role);
    final canApprove = Permissions.canApproveRequests(role);

    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _sectionCard('Appearance', [
            SwitchListTile(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              title: const Text('Dark Mode'),
              subtitle: const Text('Applies across every screen in the app', style: TextStyle(fontSize: 11)),
              secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          _sectionCard('Connectivity', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
              title: const Text('Server Connection'),
              subtitle: const Text('Change the backend URL this app talks to', style: TextStyle(fontSize: 11)),
              trailing:  Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => showServerConnectionSheet(context),
            ),
          ]),
          settingsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _errorCard('Could not load library settings.\n$e', () => ref.read(librarySettingsProvider.notifier).load()),
            data: (settings) => _LibraryTimingCard(settings: settings, canEdit: canEditSettings),
          ),
          settingsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (settings) => _BorrowingRulesCard(settings: settings, canEdit: canEditSettings),
          ),
          if (pendingExtensions.isNotEmpty)
            _sectionCard('Pending Extension Requests', [
              for (final t in pendingExtensions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.more_time_rounded, color: AppColors.warning),
                  title: Text(t.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${t.borrowerName} wants until ${t.requestedDueDate != null ? DateFormat('MMM d').format(t.requestedDueDate!) : '-'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: !canApprove
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                              onPressed: () => ref.read(remoteTransactionsProvider.notifier).approveExtension(t.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                              onPressed: () => ref.read(remoteTransactionsProvider.notifier).rejectExtension(t.id),
                            ),
                          ],
                        ),
                ),
            ]),
          feedbackAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _errorCard('Could not load feedback.\n$e', () => ref.read(feedbackProvider.notifier).load()),
            data: (feedback) => _FeedbackCard(feedback: feedback),
          ),
          _sectionCard('Library Configuration', [
            _tile(Icons.info_outline, 'Library Information', AppConstants.libraryName),
            _tile(Icons.apartment_outlined, 'Departments', '${AppConstants.departments.length} configured'),
            _tile(Icons.category_outlined, 'Categories', '${AppConstants.categories.length} configured'),
          ]),
        ],
      ),
    );
  }

  Widget _errorCard(String message, VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
        ],
      ),
    );
  }

  static Widget _sectionCard(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Library opening/closing hours + working days — visible to Students and
/// Staff too (via the same GET endpoint), editable only by the Admin here.
class _LibraryTimingCard extends ConsumerStatefulWidget {
  final LibrarySettingsModel settings;
  final bool canEdit;
  const _LibraryTimingCard({required this.settings, this.canEdit = true});

  @override
  ConsumerState<_LibraryTimingCard> createState() => _LibraryTimingCardState();
}

class _LibraryTimingCardState extends ConsumerState<_LibraryTimingCard> {
  late final _opening = TextEditingController(text: widget.settings.openingTime);
  late final _closing = TextEditingController(text: widget.settings.closingTime);
  late final _workingDays = TextEditingController(text: widget.settings.workingDays);
  late final _announcement = TextEditingController(text: widget.settings.announcement);
  bool _saving = false;
  bool _editing = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(librarySettingsProvider.notifier).update(widget.settings.copyWith(
            openingTime: _opening.text.trim(),
            closingTime: _closing.text.trim(),
            workingDays: _workingDays.text.trim(),
            announcement: _announcement.text.trim(),
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Library timing updated — students & staff will see this')));
        setState(() => _editing = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    _opening.text = widget.settings.openingTime;
    _closing.text = widget.settings.closingTime;
    _workingDays.text = widget.settings.workingDays;
    _announcement.text = widget.settings.announcement;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Library Timing', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
                ),
                if (!_editing && widget.canEdit)
                  TextButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: _editing ? _buildEditForm() : _buildReadOnly(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _readRow('Opening Time', _opening.text.isEmpty ? '—' : _opening.text),
        _readRow('Closing Time', _closing.text.isEmpty ? '—' : _closing.text),
        _readRow('Working Days', _workingDays.text.isEmpty ? '—' : _workingDays.text),
        _readRow('Announcement', _announcement.text.isEmpty ? 'None' : _announcement.text),
      ],
    );
  }

  Widget _readRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _opening, decoration: const InputDecoration(labelText: 'Opening Time', hintText: '08:30'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _closing, decoration: const InputDecoration(labelText: 'Closing Time', hintText: '18:00'))),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _workingDays, decoration: const InputDecoration(labelText: 'Working Days', hintText: 'Mon-Sat')),
        const SizedBox(height: 12),
        TextField(controller: _announcement, maxLines: 2, decoration: const InputDecoration(labelText: 'Announcement (optional)', hintText: 'e.g. Closed for maintenance on Sunday')),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _saving ? null : _cancelEdit, child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Timing'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Editable borrow/reservation limits, borrow duration, fine/day, and how
/// many extra days an approved extension grants.
class _BorrowingRulesCard extends ConsumerStatefulWidget {
  final LibrarySettingsModel settings;
  final bool canEdit;
  const _BorrowingRulesCard({required this.settings, this.canEdit = true});

  @override
  ConsumerState<_BorrowingRulesCard> createState() => _BorrowingRulesCardState();
}

class _BorrowingRulesCardState extends ConsumerState<_BorrowingRulesCard> {
  late final _studentLimit = TextEditingController(text: '${widget.settings.maxBorrowLimitStudent}');
  late final _staffLimit = TextEditingController(text: '${widget.settings.maxBorrowLimitStaff}');
  late final _reservationLimit = TextEditingController(text: '${widget.settings.maxReservationLimit}');
  late final _borrowDuration = TextEditingController(text: '${widget.settings.borrowDurationDays}');
  late final _finePerDay = TextEditingController(text: widget.settings.finePerDay.toStringAsFixed(0));
  late final _extensionDays = TextEditingController(text: '${widget.settings.extensionDaysAllowed}');
  bool _saving = false;
  bool _editing = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(librarySettingsProvider.notifier).update(widget.settings.copyWith(
            maxBorrowLimitStudent: int.tryParse(_studentLimit.text) ?? widget.settings.maxBorrowLimitStudent,
            maxBorrowLimitStaff: int.tryParse(_staffLimit.text) ?? widget.settings.maxBorrowLimitStaff,
            maxReservationLimit: int.tryParse(_reservationLimit.text) ?? widget.settings.maxReservationLimit,
            borrowDurationDays: int.tryParse(_borrowDuration.text) ?? widget.settings.borrowDurationDays,
            finePerDay: double.tryParse(_finePerDay.text) ?? widget.settings.finePerDay,
            extensionDaysAllowed: int.tryParse(_extensionDays.text) ?? widget.settings.extensionDaysAllowed,
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrowing rules updated')));
        setState(() => _editing = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    _studentLimit.text = '${widget.settings.maxBorrowLimitStudent}';
    _staffLimit.text = '${widget.settings.maxBorrowLimitStaff}';
    _reservationLimit.text = '${widget.settings.maxReservationLimit}';
    _borrowDuration.text = '${widget.settings.borrowDurationDays}';
    _finePerDay.text = widget.settings.finePerDay.toStringAsFixed(0);
    _extensionDays.text = '${widget.settings.extensionDaysAllowed}';
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Borrowing & Reservation Rules', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
                ),
                if (!_editing && widget.canEdit)
                  TextButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: _editing ? _buildEditForm() : _buildReadOnly(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _readRow('Student Borrow Limit', _studentLimit.text),
        _readRow('Staff Borrow Limit', _staffLimit.text),
        _readRow('Max Reservations', _reservationLimit.text),
        _readRow('Borrow Duration (days)', _borrowDuration.text),
        _readRow('Fine / Day (₹)', _finePerDay.text),
        _readRow('Extension Days Allowed', _extensionDays.text),
      ],
    );
  }

  Widget _readRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 170, child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _studentLimit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Student Borrow Limit'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _staffLimit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Staff Borrow Limit'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _reservationLimit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Reservations'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _borrowDuration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Borrow Duration (days)'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _finePerDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fine / Day (₹)'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _extensionDays, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Extension Days Allowed'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _saving ? null : _cancelEdit, child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Rules'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Feedback submitted by Students/Staff. Tap "Resolve" once it's been acted on.
class _FeedbackCard extends ConsumerWidget {
  final List<FeedbackItem> feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text('Student & Staff Feedback', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13)),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: feedback.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No feedback submitted yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  )
                : Column(
                    children: [
                      for (final f in feedback)
                        ListTile(
                          leading: Icon(
                            f.isResolved ? Icons.check_circle_outline : Icons.mark_email_unread_outlined,
                            color: f.isResolved ? AppColors.success : AppColors.warning,
                          ),
                          title: Text(f.senderName.isEmpty ? f.senderId : f.senderName),
                          subtitle: Text(f.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          trailing: (f.isResolved || !Permissions.canApproveRequests(ref.watch(currentRoleProvider)))
                              ? null
                              : TextButton(
                                  onPressed: () => ref.read(feedbackProvider.notifier).resolve(f.id),
                                  child: const Text('Resolve'),
                                ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
