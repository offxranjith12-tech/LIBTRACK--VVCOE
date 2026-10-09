import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_providers.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Write a message before submitting.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(feedbackServiceProvider).submit(_controller.text.trim(), _rating);
      ref.invalidate(feedbackListProvider);
      _controller.clear();
      setState(() => _rating = 5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for the feedback!')));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackListProvider);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Feedback', showBack: true),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share your feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Tell us what\'s working well or what could improve.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = starIndex),
                      icon: Icon(
                        starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.warning,
                        size: 28,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Your feedback...'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Feedback'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent Feedback'),
          const SizedBox(height: 12),
          feedbackAsync.when(
            data: (list) => list.isEmpty
                ? const EmptyState(icon: Icons.feedback_outlined, message: 'No feedback submitted yet.')
                : Column(
                    children: list.map((f) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (f.rating != null)
                              Row(
                                children: List.generate(5, (i) => Icon(
                                      i < f.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: AppColors.warning,
                                      size: 16,
                                    )),
                              ),
                            const SizedBox(height: 6),
                            Text(f.message, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${f.submittedAt.day}/${f.submittedAt.month}/${f.submittedAt.year}',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Text('Could not load feedback: $e', style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
