import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ContactLibrarianScreen extends StatelessWidget {
  const ContactLibrarianScreen({super.key});

  Future<void> _launch(BuildContext context, String urlString, String label) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label: ${urlString.replaceAll(RegExp(r'^(tel:|mailto:)'), '')}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Contact Librarian', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ── Main Librarian Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dr. S. Ramesh',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chief Librarian • VVCE Central Library',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _headerActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      onTap: () => _launch(context, 'tel:+919876543210', 'Librarian Mobile'),
                    ),
                    _headerActionButton(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      onTap: () => _launch(context, 'mailto:librarian@vvce.ac.in', 'Librarian Email'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Contact Details List ──
          const SectionHeader(title: 'Library Office Contact Details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                _contactRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: 'Ground Floor, Admin Block, VVCE Campus',
                  onTap: null,
                ),
                Divider(height: 1, color: AppColors.divider),
                _contactRow(
                  icon: Icons.phone_outlined,
                  title: 'Desk Phone',
                  value: '+91 (0821) 2345678 Ext. 104',
                  onTap: () => _launch(context, 'tel:+918212345678', 'Desk Phone'),
                ),
                Divider(height: 1, color: AppColors.divider),
                _contactRow(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: 'library@vvce.ac.in',
                  onTap: () => _launch(context, 'mailto:library@vvce.ac.in', 'Library Email'),
                ),
                Divider(height: 1, color: AppColors.divider),
                _contactRow(
                  icon: Icons.access_time_rounded,
                  title: 'Office Hours',
                  value: 'Mon - Fri: 9:00 AM - 5:00 PM',
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Assistant Librarians ──
          const SectionHeader(title: 'Assistant Librarians'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                _assistantTile(context, 'Mrs. Anita Kumar', 'Assistant Librarian (Circulation & Issues)', '+91 9845012345'),
                const SizedBox(height: 12),
                _assistantTile(context, 'Mr. Suresh Babu', 'Technical Assistant (E-Resources & Journals)', '+91 9845054321'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
      ),
    );
  }

  Widget _contactRow({required IconData icon, required String title, required String value, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.text)),
      trailing: onTap != null ? Icon(Icons.chevron_right_rounded, color: AppColors.textMuted) : null,
      onTap: onTap,
    );
  }

  Widget _assistantTile(BuildContext context, String name, String role, String phone) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
          child: Text(name[0], style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text(role, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
          onPressed: () => _launch(context, 'tel:$phone', name),
        ),
      ],
    );
  }
}
