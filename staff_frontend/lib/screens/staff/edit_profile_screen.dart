import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../providers/staff_providers.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_helper.dart';
import '../../widgets/shared_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Staff staff;
  const EditProfileScreen({super.key, required this.staff});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  String _photoBase64 = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _phoneController = TextEditingController(text: widget.staff.phone);
    _addressController = TextEditingController(text: widget.staff.address);
    _photoBase64 = widget.staff.photoUrl;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    setState(() => _photoBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Department, Designation, and Email are set once at registration
      // and cannot be changed here - only name, phone, address, and photo
      // are editable. The backend also enforces this independently.
      final updated = Staff(
        id: widget.staff.id,
        name: _nameController.text.trim(),
        department: widget.staff.department,
        designation: widget.staff.designation,
        email: widget.staff.email,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photoUrl: _photoBase64,
      );
      await ref.read(staffServiceProvider).updateProfile(updated);
      ref.invalidate(currentStaffProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = decodeAvatar(_photoBase64);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Edit Profile', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          _nameController.text.trim().isEmpty
                              ? '?'
                              : _nameController.text.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 26),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _field('Name', _nameController, Icons.badge_outlined),
          const SizedBox(height: 12),
          _field('Phone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _field('Address', _addressController, Icons.home_outlined, maxLines: 2),

          const SizedBox(height: 20),
          Text('Set at registration - contact an administrator to change these',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          const SizedBox(height: 8),
          _lockedField('Department', widget.staff.department, Icons.apartment_outlined),
          const SizedBox(height: 12),
          _lockedField('Designation', widget.staff.designation, Icons.work_outline_rounded),
          const SizedBox(height: 12),
          _lockedField('Email', widget.staff.email, Icons.email_outlined),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _lockedField(String label, String value, IconData icon) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        suffixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
