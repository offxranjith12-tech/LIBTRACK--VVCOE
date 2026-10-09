import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/service_providers.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';

/// Profile screen — every action here is wired to the real backend:
/// Edit Profile and Change Password hit `/api/v1/me`, the camera badge
/// uploads a real profile picture to `/api/v1/me/avatar`, Activity Log
/// reads real recent transactions, and Logout clears the stored JWT before
/// navigating away.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      // Use XFile.readAsBytes() directly — never wrap picked.path in dart:io's
      // File(). File() depends on dart:io's platform bindings and throws
      // "Unsupported operation: _Namespace" on web/desktop builds. XFile's
      // own readAsBytes() works identically across mobile, web, and desktop.
      final bytes = await picked.readAsBytes();
      await ref.read(meProfileProvider.notifier).uploadAvatar(bytes: bytes, filename: picked.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload picture: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(meProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('Could not load your profile.\n$err', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(meProfileProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (admin) {
          final avatarUrl = ApiClient.instance.resolveFileUrl(admin.avatarUrl);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary,
                          backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(
                                  admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                              child: _uploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(admin.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      admin.role == 'LIBRARIAN' ? 'Librarian' : admin.role == 'STAFF' ? 'Staff' : admin.role == 'STUDENT' ? 'Student' : 'Administrator',
                      style:  TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _infoTile(Icons.badge_outlined, 'Login ID', admin.loginId),
                    _infoTile(Icons.email_outlined, 'Email', admin.email),
                    _infoTile(Icons.phone_outlined, 'Phone', admin.phone.isEmpty ? '-' : admin.phone),
                    if (admin.department != null) _infoTile(Icons.apartment_outlined, 'Department', admin.department!),
                    if (admin.designationOrSemester != null) _infoTile(Icons.work_outline, 'Designation', admin.designationOrSemester!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _actionTile(context, Icons.edit_outlined, 'Edit Profile', () => _showEditProfileSheet(context, ref, admin)),
                    _actionTile(context, Icons.lock_outline, 'Change Password', () => _showChangePasswordSheet(context, ref)),
                    _actionTile(context, Icons.history_rounded, 'Activity Log', () => _showActivityLog(context, ref)),
                    _actionTile(context, Icons.settings_outlined, 'System Settings', () => context.push('/settings')),
                    _actionTile(context, Icons.help_outline_rounded, 'Help & Support', () => _showHelpSupport(context)),
                    _actionTile(context, Icons.logout_rounded, 'Logout', () => _logout(context, ref), color: AppColors.danger),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style:  TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final resolvedColor = color ?? AppColors.text;
    return ListTile(
      leading: Icon(icon, color: color == AppColors.danger ? AppColors.danger : AppColors.textSecondary),
      title: Text(label, style: TextStyle(color: resolvedColor, fontWeight: FontWeight.w500)),
      trailing:  Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access LibTrack.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log Out', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed != true) return;
    // Clearing the stored JWT here (not just navigating) is what actually
    // signs the user out — navigation alone would leave the token valid.
    await ref.read(authServiceProvider).logout();
    if (context.mounted) context.go('/login');
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, dynamic admin) {
    final name = TextEditingController(text: admin.name);
    final phone = TextEditingController(text: admin.phone);
    final email = TextEditingController(text: admin.email);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                enabled: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'College email is fixed and cannot be changed',
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          // Email is intentionally omitted — it's read-only and the
                          // backend ignores it even if sent, but we keep the client
                          // in sync with that rule rather than pretending otherwise.
                          await ref.read(meProfileProvider.notifier).update(
                                name: name.text.trim(),
                                phone: phone.text.trim(),
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    final current = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Change Password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
              TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 12),
              TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
              const SizedBox(height: 12),
              TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (newPass.text.length < 6) {
                          setState(() => error = 'New password must be at least 6 characters');
                          return;
                        }
                        if (newPass.text != confirm.text) {
                          setState(() => error = 'Passwords do not match');
                          return;
                        }
                        setState(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await ref.read(meProfileProvider.notifier).changePassword(
                                currentPassword: current.text,
                                newPassword: newPass.text,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
                          }
                        } catch (e) {
                          setState(() {
                            saving = false;
                            error = 'Could not change password: $e';
                          });
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityLog(BuildContext context, WidgetRef ref) {
    final transactions = ref.read(remoteTransactionsProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: transactions.isEmpty
                    ?  Center(child: Text('No recent activity', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: controller,
                        itemCount: transactions.length,
                        itemBuilder: (context, i) {
                          final t = transactions[i];
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                            title: Text(t.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${t.borrowerName} • ${t.status.name}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For technical issues with LibTrack, contact the college IT desk, or reach the library administrator directly through the college email system.\n\n'
          'Common tasks:\n'
          '• Adding books — Books tab → + button\n'
          '• Adding students/staff — Users tab → Add\n'
          '• Approving return extensions — Settings → Pending Extension Requests',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }
}
