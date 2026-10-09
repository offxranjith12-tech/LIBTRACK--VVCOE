import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/student_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ResponsiveCenter(
            maxWidth: 800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: student.name,
                  reg: student.registerNumber,
                  dept: student.department,
                  sem: student.semester,
                  photoUrl: student.photoUrl,
                ),
                const SizedBox(height: 20),
                SoftCard(
                  child: Column(
                    children: [
                      _infoRow(context, Icons.school_rounded, 'Department', student.department),
                      const Divider(height: 24),
                      _infoRow(context, Icons.calendar_today_rounded, 'Semester', student.semester),
                      const Divider(height: 24),
                      _infoRow(context, Icons.email_rounded, 'Email', student.email),
                      const Divider(height: 24),
                      _infoRow(context, Icons.phone_rounded, 'Phone Number', student.phone),
                      const Divider(height: 24),
                      _infoRow(context, Icons.badge_rounded, 'Library Card No.', student.libraryCardNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _actionTile(context, Icons.edit_rounded, 'Edit Profile', () => context.push('/profile/edit')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.lock_reset_rounded, 'Change Password', () => context.push('/settings/change-password')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.settings_rounded, 'Settings', () => context.push('/settings')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.help_outline_rounded, 'Help', () => context.push('/help')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.logout_rounded, 'Logout', () => _logout(context, ref), color: AppColors.danger),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('More', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primaryRed),
                        title: const Text('Dark Mode'),
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                      const Divider(height: 1),
                      _actionTile(context, Icons.favorite_border_rounded, 'Wishlist', () => context.push('/wishlist')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.history_rounded, 'Recently Viewed Books', () => _snack(context, 'Recently Viewed')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.recommend_rounded, 'Book Recommendations', () => _snack(context, 'Recommendations')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.category_rounded, 'Favorite Categories', () => _snack(context, 'Favorite Categories')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.timeline_rounded, 'Reading History', () => _snack(context, 'Reading History')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.picture_as_pdf_rounded, 'Download Library Rules PDF', () => _snack(context, 'Downloading PDF...')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.access_time_rounded, 'Library Timing', () => _showTiming(context)),
                      const Divider(height: 1),
                      _actionTile(context, Icons.feedback_rounded, 'Feedback Form', () => context.push('/feedback')),
                      const Divider(height: 1),
                      _actionTile(context, Icons.support_agent_rounded, 'Contact Librarian', () => _contactLibrarian()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(apiServiceProvider).logout();
    if (!context.mounted) return;
    context.go('/login');
  }

  void _showTiming(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Library Timing'),
        content: const Text('Monday – Saturday: 8:00 AM – 6:00 PM\nExam Week: 8:00 AM – 8:00 PM\nSunday: Closed'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _contactLibrarian() async {
    final uri = Uri(scheme: 'mailto', path: 'librarian@vvcoe.org', query: 'subject=Library Query');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryRed).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primaryRed, size: 18),
      ),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textGrey),
      onTap: onTap,
    );
  }
}

/// Gradient hero header, visually consistent with the dashboard's
/// profile card, with everything centered and evenly spaced.
class _ProfileHeader extends StatelessWidget {
  final String name, reg, dept, sem;
  final String? photoUrl;
  const _ProfileHeader({required this.name, required this.reg, required this.dept, required this.sem, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryRed.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StudentAvatar(
            photoUrl: photoUrl,
            name: name,
            radius: 42,
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            reg,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(dept),
              _pill(sem),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
