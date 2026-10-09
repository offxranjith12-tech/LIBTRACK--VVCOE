import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/student.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';

/// Admin's "Add / Edit Staff / Librarian" form. Toggle the role to create a
/// Librarian account instead of regular teaching Staff — the library can
/// have any number of librarians, each getting their own staffId + password
/// to log in with. The email must be the college's own domain
/// (e.g. ranjith@vvcoe.org); personal Gmail addresses are rejected.
///
/// Pass [existing] to edit an already-registered staff member in place;
/// leave it null to add a new one. The staff ID is immutable once created
/// (it's the login ID), and the password fields are optional in edit mode —
/// leaving them blank keeps the account's current password unchanged.
class AddStaffScreen extends ConsumerStatefulWidget {
  final Staff? existing;
  const AddStaffScreen({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _staffId = TextEditingController(text: widget.existing?.staffId ?? '');
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _designation = TextEditingController(text: widget.existing?.designation ?? '');
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late String _department = widget.existing?.department ?? AppConstants.departments.first;
  late StaffRole _role = widget.existing?.role ?? StaffRole.staff;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_staffId, _name, _designation, _email, _phone, _password, _confirmPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final designation = _designation.text.trim().isEmpty
          ? (_role == StaffRole.librarian ? 'Librarian' : 'Faculty')
          : _designation.text.trim();
      if (widget.isEdit) {
        await ref.read(staffNotifierProvider.notifier).update(widget.existing!.id, {
          'name': _name.text.trim(),
          'department': _department,
          'designation': designation,
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'role': _role == StaffRole.librarian ? 'LIBRARIAN' : 'STAFF',
          if (_password.text.trim().isNotEmpty) 'password': _password.text,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_name.text.trim()} updated successfully')),
        );
      } else {
        final staff = await ref.read(staffRemoteServiceProvider).create(
              staffId: _staffId.text.trim(),
              name: _name.text.trim(),
              department: _department,
              designation: designation,
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              password: _password.text,
              role: _role == StaffRole.librarian ? 'LIBRARIAN' : 'STAFF',
            );
        if (!mounted) return;
        ref.read(staffNotifierProvider.notifier).load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${staff.name} added successfully')),
        );
      }
      context.pop();
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('vvcoe.org') || text.contains('college')) {
      return 'Only official college email addresses (@${AppConstants.collegeEmailDomain}) are allowed. '
          'Personal Gmail or other personal addresses cannot be used.';
    }
    return widget.isEdit ? 'Could not update staff: $text' : 'Could not add staff: $text';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Staff / Librarian' : 'Add Staff / Librarian')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ),
            _label('Account Type'),
            SegmentedButton<StaffRole>(
              segments: const [
                ButtonSegment(value: StaffRole.staff, label: Text('Staff'), icon: Icon(Icons.badge_outlined)),
                ButtonSegment(value: StaffRole.librarian, label: Text('Librarian'), icon: Icon(Icons.local_library_outlined)),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _role == StaffRole.librarian
                    ? 'Librarians get a full login of their own — any number of librarians can be added, each with an independent ID and password.'
                    : 'Regular teaching staff account with library borrowing privileges.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ),
            _field('Staff ID', _staffId, hint: 'e.g. STF1002', required: true, enabled: !widget.isEdit),
            if (widget.isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children:  [
                    Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Staff ID is the login ID and can\'t be changed', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
            _field('Full Name', _name, required: true),
            _label('Department'),
            DropdownButtonFormField<String>(
              initialValue: _department,
              items: [for (final d in AppConstants.departments) DropdownMenuItem(value: d, child: Text(d))],
              onChanged: (v) => setState(() => _department = v ?? _department),
            ),
            const SizedBox(height: 14),
            _field('Designation', _designation, hint: _role == StaffRole.librarian ? 'e.g. Chief Librarian' : 'e.g. Assistant Professor'),
            _field(
              'College Gmail',
              _email,
              hint: 'e.g. ranjith@vvcoe.org',
              required: true,
              keyboardType: TextInputType.emailAddress,
              validator: _validateCollegeEmail,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Only the college domain (@vvcoe.org) is accepted. Personal Gmail/Yahoo accounts cannot log in to LibTrack.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            _field('Phone Number', _phone, keyboardType: TextInputType.phone),
            _field(
              widget.isEdit ? 'New Password (optional)' : 'Password',
              _password,
              required: !widget.isEdit,
              obscure: true,
              hint: widget.isEdit ? 'Leave blank to keep current password' : null,
              validator: widget.isEdit ? _validateOptionalPassword : _validatePassword,
            ),
            _field(
              widget.isEdit ? 'Confirm New Password' : 'Confirm Password',
              _confirmPassword,
              required: !widget.isEdit,
              obscure: true,
              validator: _validateConfirmPassword,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(widget.isEdit ? Icons.save_outlined : Icons.person_add_alt_1_rounded),
              label: Text(_saving
                  ? 'Saving...'
                  : (widget.isEdit ? 'Save Changes' : (_role == StaffRole.librarian ? 'Add Librarian' : 'Add Staff'))),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateCollegeEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'College email is required';
    if (!isCollegeEmail(value)) {
      return 'Must be a college email ending in @${AppConstants.collegeEmailDomain}';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateOptionalPassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_password.text.isEmpty && (value == null || value.isEmpty)) return null;
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    bool obscure = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null),
      ),
    );
  }
}
