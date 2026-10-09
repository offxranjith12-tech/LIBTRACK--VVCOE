import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../widgets/responsive.dart';
import '../../widgets/soft_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How many books can I borrow at once?',
      'Students can borrow up to 2 books at a time. Each loan period is 14 days from the date of issue.',
    ),
    (
      'How do I renew a borrowed book?',
      'Go to My Books, find the book under the Current tab, and tap Renew. You can renew a book up to 2 times, as long as no one else has reserved it.',
    ),
    (
      'What happens if I return a book late?',
      'A fine of ₹5 per day is charged for every day a book is overdue, starting the day after the due date.',
    ),
    (
      'How do reservations work?',
      'If a book is currently unavailable, you can join the queue by tapping Reserve. You\'ll move up the queue as copies are returned, and you\'ll be notified when it\'s your turn.',
    ),
    (
      'What are "Regulation" books?',
      'These are the official prescribed textbooks for your semester\'s syllabus (e.g. R-2021 Regulation). Use the Regulation Books filter on the Search screen to find them quickly.',
    ),
    (
      'How do I update my profile photo or contact details?',
      'Go to Profile → Edit Profile. You can update your name, email, phone number, and profile photo there.',
    ),
    (
      'I forgot my password. What do I do?',
      'Contact the librarian using the "Contact Librarian" option on your Profile page, and they can help you reset it.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ResponsiveCenter(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Frequently Asked Questions', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < _faqs.length; i++) ...[
                        ExpansionTile(
                          iconColor: AppColors.primaryRed,
                          collapsedIconColor: AppColors.textGrey,
                          title: Text(_faqs[i].$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_faqs[i].$2, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.4)),
                          ],
                        ),
                        if (i != _faqs.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Still need help?', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.feedback_rounded, color: AppColors.primaryRed),
                        title: const Text('Send Feedback'),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textGrey),
                        onTap: () => context.push('/feedback'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded, color: AppColors.primaryRed),
                        title: const Text('Contact Librarian'),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textGrey),
                        onTap: () async {
                          final uri = Uri(scheme: 'mailto', path: 'librarian@vvcoe.org', query: 'subject=Library Query');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),
                    ],
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
