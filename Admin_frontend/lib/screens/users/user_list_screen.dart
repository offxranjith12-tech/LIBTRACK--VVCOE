import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/auth/permissions.dart';
import '../../models/student.dart';
import '../../providers/user_provider.dart';
import '../../widgets/alerts_action_button.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/status_badge.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: const [AlertsActionButton(), SizedBox(width: 8)],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Students'), Tab(text: 'Staff / Librarians')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              hintText: 'Search by name, ID, or department...',
              onChanged: (v) => ref.read(userSearchQueryProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final dept = ref.watch(userDepartmentFilterProvider);
                    return ActionChip(
                      label: Text(dept ?? 'Department'),
                      avatar: Icon(Icons.arrow_drop_down, size: 18, color: dept != null ? AppColors.primary : AppColors.textSecondary),
                      backgroundColor: dept != null ? AppColors.primary.withValues(alpha: 0.12) : null,
                      labelStyle: TextStyle(color: dept != null ? AppColors.primary : AppColors.text),
                      onPressed: () => _showDepartmentPicker(context, ref, dept),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_StudentsTab(), _StaffTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (context, _) {
          final isStudentsTab = _tab.index == 0;
          final role = ref.watch(currentRoleProvider);
          final allowed = isStudentsTab ? Permissions.canManageStudents(role) : Permissions.canManageStaff(role);
          if (!allowed) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => context.push(isStudentsTab ? '/users/students/add' : '/users/staff/add'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(isStudentsTab ? 'Add Student' : 'Add Staff'),
          );
        },
      ),
    );
  }

  void _showDepartmentPicker(BuildContext context, WidgetRef ref, String? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Department', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        title: const Text('All'),
                        trailing: current == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                        onTap: () {
                          ref.read(userDepartmentFilterProvider.notifier).state = null;
                          Navigator.pop(context);
                        },
                      ),
                      for (final d in AppConstants.departments)
                        ListTile(
                          title: Text(d),
                          trailing: current == d ? const Icon(Icons.check, color: AppColors.primary) : null,
                          onTap: () {
                            ref.read(userDepartmentFilterProvider.notifier).state = d;
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  const _StudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsNotifierProvider);
    final students = ref.watch(filteredStudentsProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: 'Could not load students from the server.\n$err',
        onRetry: () => ref.read(studentsNotifierProvider.notifier).load(),
      ),
      data: (_) {
        if (students.isEmpty) {
          return Center(child: Text('No students found', style: TextStyle(color: AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(studentsNotifierProvider.notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = students[i];
              final canManage = Permissions.canManageStudents(ref.watch(currentRoleProvider));
              return _UserTile(
                title: s.name,
                subtitle: '${s.registerNumber} • ${s.department} • Sem ${s.semester}',
                trailing: '${s.borrowedBooksCount} borrowed',
                email: s.email,
                blocked: s.status == UserStatus.blocked,
                onView: () => _showStudentDetail(context, s, canManage: canManage),
                onEdit: canManage ? () => context.push('/users/students/edit', extra: s) : null,
                onBlockToggle: canManage ? () => ref.read(studentsNotifierProvider.notifier).toggleBlock(s.id) : null,
                onDelete: canManage ? () => ref.read(studentsNotifierProvider.notifier).delete(s.id) : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showStudentDetail(BuildContext context, Student s, {required bool canManage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _UserDetailSheet(
        name: s.name,
        idLabel: 'Register Number',
        idValue: s.registerNumber,
        rows: [
          _DetailRow('Department', s.department),
          _DetailRow('Semester', 'Semester ${s.semester}'),
          _DetailRow('Email', s.email),
          _DetailRow('Phone', s.phone.isEmpty ? '—' : s.phone),
          _DetailRow('Books Borrowed', '${s.borrowedBooksCount} / ${s.borrowLimit}'),
          _DetailRow('Status', s.status == UserStatus.blocked ? 'Blocked' : 'Active'),
          _DetailRow('Joined On', DateFormat('MMM d, yyyy').format(s.joinedOn)),
        ],
        onEdit: !canManage
            ? null
            : () {
                Navigator.pop(context);
                context.push('/users/students/edit', extra: s);
              },
      ),
    );
  }
}

class _StaffTab extends ConsumerWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffNotifierProvider);
    final staff = ref.watch(filteredStaffProvider);

    return staffAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: 'Could not load staff from the server.\n$err',
        onRetry: () => ref.read(staffNotifierProvider.notifier).load(),
      ),
      data: (_) {
        if (staff.isEmpty) {
          return Center(child: Text('No staff found', style: TextStyle(color: AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(staffNotifierProvider.notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = staff[i];
              final canManage = Permissions.canManageStaff(ref.watch(currentRoleProvider));
              return _UserTile(
                title: s.name,
                subtitle: '${s.staffId} • ${s.department} • ${s.designation}',
                trailing: '${s.borrowedBooksCount} borrowed',
                email: s.email,
                blocked: s.status == UserStatus.blocked,
                roleBadge: s.isLibrarian ? 'Librarian' : null,
                onView: () => _showStaffDetail(context, s, canManage: canManage),
                onEdit: canManage ? () => context.push('/users/staff/edit', extra: s) : null,
                onBlockToggle: canManage ? () => ref.read(staffNotifierProvider.notifier).toggleBlock(s.id) : null,
                onDelete: canManage ? () => ref.read(staffNotifierProvider.notifier).delete(s.id) : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showStaffDetail(BuildContext context, Staff s, {required bool canManage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _UserDetailSheet(
        name: s.name,
        idLabel: 'Staff ID',
        idValue: s.staffId,
        rows: [
          _DetailRow('Role', s.isLibrarian ? 'Librarian' : 'Staff'),
          _DetailRow('Department', s.department),
          _DetailRow('Designation', s.designation.isEmpty ? '—' : s.designation),
          _DetailRow('Email', s.email),
          _DetailRow('Phone', s.phone.isEmpty ? '—' : s.phone),
          _DetailRow('Books Borrowed', '${s.borrowedBooksCount} / ${s.borrowLimit}'),
          _DetailRow('Status', s.status == UserStatus.blocked ? 'Blocked' : 'Active'),
          _DetailRow('Joined On', DateFormat('MMM d, yyyy').format(s.joinedOn)),
        ],
        onEdit: !canManage
            ? null
            : () {
                Navigator.pop(context);
                context.push('/users/staff/edit', extra: s);
              },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final String email;
  final bool blocked;
  final String? roleBadge;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onBlockToggle;
  final VoidCallback? onDelete;

  const _UserTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.email,
    required this.blocked,
    this.roleBadge,
    required this.onView,
    this.onEdit,
    this.onBlockToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onView,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(title.isNotEmpty ? title[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      if (roleBadge != null) ...[
                        const SizedBox(width: 6),
                        StatusBadge(label: roleBadge!, color: AppColors.info),
                      ],
                      if (blocked) ...[
                        const SizedBox(width: 6),
                        const StatusBadge(label: 'Blocked', color: AppColors.danger),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(trailing, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'view') onView();
                if (v == 'edit') onEdit?.call();
                if (v == 'block') onBlockToggle?.call();
                if (v == 'delete') _confirmDelete(context);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onBlockToggle != null) PopupMenuItem(value: 'block', child: Text(blocked ? 'Unblock' : 'Block')),
                if (onDelete != null) const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text('This permanently removes $title\'s LibTrack account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}

/// Read-only detail sheet used by the "View" action for both students and
/// staff — shows every field the backend has for that account, with a
/// shortcut into edit mode.
class _UserDetailSheet extends StatelessWidget {
  final String name;
  final String idLabel;
  final String idValue;
  final List<_DetailRow> rows;
  final VoidCallback? onEdit;

  const _UserDetailSheet({
    required this.name,
    required this.idLabel,
    required this.idValue,
    required this.rows,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                        Text('$idLabel: $idValue', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...rows.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 130, child: Text(r.label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                      Expanded(child: Text(r.value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (onEdit != null)
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
