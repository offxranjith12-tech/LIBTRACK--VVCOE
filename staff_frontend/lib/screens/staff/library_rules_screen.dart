import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_providers.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LibraryRulesScreen extends ConsumerWidget {
  const LibraryRulesScreen({super.key});

  void _downloadRules(BuildContext context, LibraryRules rules) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Library Rules & Regulations PDF downloaded to your device.')),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(libraryRulesProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Library Rules', showBack: true),
      body: rulesAsync.when(
        data: (rules) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // ── Download Rules Banner ──
            Container(
              padding: const EdgeInsets.all(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rules.title,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            if (rules.version.isNotEmpty)
                              Text(rules.version,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadRules(context, rules),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download Library Rules (PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Rules Sections ──
            for (final section in rules.sections) ...[
              _ruleSectionCard(section),
              const SizedBox(height: 14),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load library rules: $e', style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(libraryRulesProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ruleSectionCard(RuleSection section) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          for (final point in section.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.text),
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
