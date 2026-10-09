import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/student.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';

/// Admin's "Add / Edit Student" form. The college email MUST be on the
/// @vvcoe.org domain (e.g. r23cs065@vvcoe.org) — personal Gmail/Yahoo/etc.
/// addresses are rejected both here (instant feedback) and again on the
/// server (source of truth), so a request can never sneak through.
///
/// Pass [existing] to edit an already-registered student in place; leave it
/// null to add a new one. The register number is immutable once created
/// (it's the login ID), and the password fields are optional in edit mode —
/// leaving them blank keeps the student's current password unchanged.
class AddStudentScreen extends ConsumerStatefulWidget {
  final Student? existing;
  const AddStudentScreen({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _registerNumber = TextEditingController(text: widget.existing?.registerNumber ?? '');
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _semester = TextEditingController(text: (widget.existing?.semester ?? 1).toString());
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late String _department = widget.existing?.department ?? AppConstants.departments.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_registerNumber, _name, _semester, _email, _phone, _password, _confirmPassword]) {
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
      if (widget.isEdit) {
        await ref.read(studentsNotifierProvider.notifier).update(widget.existing!.id, {
          'name': _name.text.trim(),
          'department': _department,
          'semester': int.tryParse(_semester.text) ?? widget.existing!.semester,
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          if (_password.text.trim().isNotEmpty) 'password': _password.text,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_name.text.trim()} updated successfully')),
        );
      } else {
        final student = await ref.read(studentRemoteServiceProvider).create(
              registerNumber: _registerNumber.text.trim(),
              name: _name.text.trim(),
              department: _department,
              semester: int.tryParse(_semester.text) ?? 1,
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              password: _password.text,
            );
        if (!mounted) return;
        ref.read(studentsNotifierProvider.notifier).load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} added successfully')),
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
    return widget.isEdit ? 'Could not update student: $text' : 'Could not add student: $text';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Student' : 'Add Student')),
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
            _field(
              'Register Number',
              _registerNumber,
              hint: 'e.g. 23CS065',
              required: true,
              enabled: !widget.isEdit,
            ),
            if (widget.isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Register number is the login ID and can\'t be changed', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
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
            _field('Semester', _semester, required: true, keyboardType: TextInputType.number),
            _field(
              'College Gmail',
              _email,
              hint: 'e.g. r23cs065@vvcoe.org',
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
              label: Text(_saving ? 'Saving...' : (widget.isEdit ? 'Save Changes' : 'Add Student')),
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
