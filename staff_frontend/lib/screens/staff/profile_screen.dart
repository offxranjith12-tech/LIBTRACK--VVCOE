import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_helper.dart';
import '../../widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).logout();
      ref.invalidate(isLoggedInProvider);
      ref.read(staffNavIndexProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(currentStaffProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 20, 12, isWide ? 32 : 20, 24),
            children: [
              Text('Profile',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              staffAsync.when(
                data: (staff) {
                  final avatar = decodeAvatar(staff.photoUrl);
                  return Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => openPhotoViewer(context,
                              name: staff.name, image: avatar),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage: avatar,
                            child: avatar == null
                                ? Text(
                                    staff.name
                                        .trim()
                                        .split(' ')
                                        .where((e) => e.isNotEmpty)
                                        .map((e) => e[0])
                                        .take(2)
                                        .join(),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 28),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(staff.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('${staff.designation} • ${staff.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('Could not load profile: $e',
                        style:
                            const TextStyle(color: AppColors.danger))),
              ),
              const SizedBox(height: 24),

              staffAsync.maybeWhen(
                data: (staff) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                          Icons.badge_outlined, 'Department', staff.department),
                      Divider(height: 1, color: AppColors.divider),
                      _infoRow(
                          Icons.email_outlined, 'Email', staff.email),
                      Divider(height: 1, color: AppColors.divider),
                      _infoRow(
                          Icons.phone_outlined, 'Phone', staff.phone),
                      if (staff.address.isNotEmpty) ...[
                        Divider(height: 1, color: AppColors.divider),
                        _infoRow(
                            Icons.home_outlined, 'Address', staff.address),
                      ],
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  children: [
                    _optionTile(context, Icons.edit_outlined, 'Edit Profile',
                        onTap: () {
                      staffAsync.whenData(
                          (staff) => context.push('/edit-profile', extra: staff));
                    }),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(context, Icons.lock_outline_rounded,
                        'Change Password',
                        onTap: () => context.push('/change-password')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(context, Icons.feedback_outlined, 'Feedback',
                        onTap: () => context.push('/feedback')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(
                        context, Icons.favorite_border_rounded, 'Wishlist',
                        onTap: () => context.push('/wishlist')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(context, Icons.history_rounded,
                        'Recently Viewed Books',
                        onTap: () => context.push('/recently-viewed')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(
                        context, Icons.schedule_rounded, 'Library Timings',
                        onTap: () => context.push('/library-timings')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(
                        context, Icons.picture_as_pdf_outlined, 'Download Library Rules',
                        onTap: () => context.push('/library-rules')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(
                        context, Icons.support_agent_rounded, 'Contact Librarian',
                        onTap: () => context.push('/contact-librarian')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(context, Icons.settings_outlined, 'Settings',
                        onTap: () => context.push('/settings')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(
                        context, Icons.help_outline_rounded, 'Help & Support',
                        onTap: () => context.push('/help')),
                    Divider(height: 1, color: AppColors.divider),
                    _optionTile(
                        context, Icons.logout_rounded, 'Logout',
                        color: AppColors.danger,
                        onTap: () => _confirmLogout(context, ref)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, IconData icon, String label,
      {Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.text),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.text,
              fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
