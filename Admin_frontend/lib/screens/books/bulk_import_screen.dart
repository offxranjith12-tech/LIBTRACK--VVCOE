import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/book_remote_service.dart';
import '../../providers/remote_book_search_provider.dart';
import '../../providers/service_providers.dart';

/// Bulk-import books from a CSV or Excel (.xlsx) file — uploads the raw
/// file to the backend, which parses it and batch-inserts every row into
/// MySQL server-side. Nothing is parsed on the phone, so this comfortably
/// handles 9,000-10,000+ row catalogues.
///
/// Expected columns (header row required, any order):
/// title, author, publisher, isbn, edition, category, department,
/// rackNumber, shelfNumber, regulation, totalCopies, description
class BulkImportBooksScreen extends ConsumerStatefulWidget {
  const BulkImportBooksScreen({super.key});

  @override
  ConsumerState<BulkImportBooksScreen> createState() => _BulkImportBooksScreenState();
}

enum _ImportStep { pick, uploading, done, failed }

class _BulkImportBooksScreenState extends ConsumerState<BulkImportBooksScreen> {
  _ImportStep _step = _ImportStep.pick;
  String? _fileName;
  BulkImportResult? _result;
  String? _errorMessage;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() {
        _step = _ImportStep.failed;
        _errorMessage = 'Could not read the selected file.';
      });
      return;
    }

    setState(() {
      _fileName = file.name;
      _step = _ImportStep.uploading;
    });

    try {
      final importResult = await ref.read(bookRemoteServiceProvider).bulkImportBytes(file.bytes!, file.name);
      ref.read(bookSearchControllerProvider.notifier).refresh();
      setState(() {
        _result = importResult;
        _step = _ImportStep.done;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e\n\nCheck that the backend is running and reachable at the configured base URL.';
        _step = _ImportStep.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Import Books')),
      body: switch (_step) {
        _ImportStep.pick => _buildPickStep(),
        _ImportStep.uploading => _buildUploadingStep(),
        _ImportStep.done => _buildDoneStep(),
        _ImportStep.failed => _buildFailedStep(),
      },
    );
  }

  Widget _buildPickStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  SizedBox(width: 8),
                  Text('Required columns', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'title, author, publisher, isbn, edition, category, department, '
                'rackNumber, shelfNumber, regulation, totalCopies, description',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                'Only title, author, isbn, category, department, totalCopies are mandatory.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'The file is parsed and batch-inserted on the server — handles 9,000+ rows in seconds.',
                      style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: _pickAndUpload,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Tap to select a CSV or Excel (.xlsx) file', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Uploads straight to the database', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Uploading ${_fileName ?? "file"}...', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Large files (9,000+ rows) may take a few seconds while the\nserver batch-inserts everything into MySQL.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneStep() {
    final result = _result!;
    final hasErrors = result.errors.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 56),
              const SizedBox(height: 12),
              Text('${result.importedCount} of ${result.totalRows} books imported',
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Completed in ${(result.durationMs / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        if (hasErrors) ...[
          const SizedBox(height: 16),
          Text('${result.skippedCount} row(s) skipped', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...result.errors.take(20).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $e', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              )),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Books'),
        ),
      ],
    );
  }

  Widget _buildFailedStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 56),
            const SizedBox(height: 16),
            const Text('Import failed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _step = _ImportStep.pick),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
