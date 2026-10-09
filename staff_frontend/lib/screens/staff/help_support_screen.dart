import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I reserve a book for myself?',
      'Search for the book, then tap "Reserve". If a copy is free it\'s held for you to collect at the desk. If every copy is out, you\'ll join the queue with priority over student reservations.'
    ),
    (
      'How is a reservation different from borrowing?',
      'The staff app reserves a copy for you - the actual borrowing/checkout still happens in person at the library counter once you collect the book.'
    ),
    (
      'How do reservations work?',
      'When a reserved book becomes available, its status changes to "Ready to Collect" in My Books. Visit the desk to pick it up, then mark it "Collected" in the app.'
    ),
    (
      'Can I change my password?',
      'Yes — go to Profile and tap "Change Password".'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Help & Support', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Central Library Desk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('library@vvce.ac.in • +91 422 000 0000', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Frequently Asked Questions'),
          const SizedBox(height: 12),
          ..._faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadows.soft,
                ),
                child: ExpansionTile(
                  title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textMuted,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
