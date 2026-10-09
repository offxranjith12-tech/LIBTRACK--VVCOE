import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LibraryTimingsScreen extends ConsumerWidget {
  const LibraryTimingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timingsAsync = ref.watch(libraryTimingsProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Library Timings', showBack: true),
      body: timingsAsync.when(
        data: (timings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: timings.schedule.map((d) {
                  final isToday = d.day == _todayName();
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: d != timings.schedule.last
                          ? Border(bottom: BorderSide(color: AppColors.divider))
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            d.day,
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday ? AppColors.primary : AppColors.text,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            d.hours,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: d.closed ? AppColors.danger : AppColors.textMuted,
                              fontWeight: d.closed ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (timings.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(timings.note, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
                  ],
                ),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Could not load timings: $e', style: const TextStyle(color: AppColors.danger))),
      ),
    );
  }

  String _todayName() {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[DateTime.now().weekday - 1];
  }
}
