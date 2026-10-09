import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../providers/remote_book_search_provider.dart';
import '../../providers/service_providers.dart';

/// Add/Edit Book — saves straight to the backend (POST/PUT `/books`),
/// which persists to MySQL. No local/mock state involved.
class AddEditBookScreen extends ConsumerStatefulWidget {
  final String? bookId;
  const AddEditBookScreen({super.key, this.bookId});

  @override
  ConsumerState<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends ConsumerState<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _author = TextEditingController();
  final _publisher = TextEditingController();
  final _isbn = TextEditingController();
  final _edition = TextEditingController();
  final _rack = TextEditingController();
  final _shelf = TextEditingController();
  final _totalCopies = TextEditingController(text: '1');
  final _description = TextEditingController();

  String _category = AppConstants.categories.first;
  String _department = AppConstants.departments.first;
  String? _regulation;

  // Book cover: holds the freshly-picked image (not yet uploaded) plus
  // whatever cover URL the backend already has for this book (edit mode).
  XFile? _pickedCover;
  Uint8List? _pickedCoverBytes;
  String? _existingCoverUrl;
  bool _uploadingCover = false;

  bool get _isEditing => widget.bookId != null;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final book = await ref.read(bookRemoteServiceProvider).getById(widget.bookId!);
      _title.text = book.title;
      _author.text = book.author;
      _publisher.text = book.publisher;
      _isbn.text = book.isbn;
      _edition.text = book.edition;
      _rack.text = book.rackNumber;
      _shelf.text = book.shelfNumber;
      _totalCopies.text = book.totalCopies.toString();
      _description.text = book.description;
      _category = book.category.isEmpty ? _category : book.category;
      _department = book.department.isEmpty ? _department : book.department;
      _regulation = book.regulation.isEmpty ? null : book.regulation;
      _existingCoverUrl = book.coverUrl.isEmpty ? null : book.coverUrl;
    } catch (e) {
      _loadError = 'Could not load this book: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _author, _publisher, _isbn, _edition, _rack, _shelf, _totalCopies, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedCover = picked;
        _pickedCoverBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<void> _uploadCoverIfNeeded(String bookId) async {
    if (_pickedCover == null || _pickedCoverBytes == null) return;
    setState(() => _uploadingCover = true);
    try {
      await ref.read(bookRemoteServiceProvider).uploadCover(
            bookId,
            bytes: _pickedCoverBytes!,
            filename: _pickedCover!.name,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Book saved, but cover upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'title': _title.text.trim(),
      'author': _author.text.trim(),
      'publisher': _publisher.text.trim(),
      'isbn': _isbn.text.trim(),
      'edition': _edition.text.trim(),
      'category': _category,
      'department': _department,
      'rackNumber': _rack.text.trim(),
      'shelfNumber': _shelf.text.trim(),
      'regulation': _regulation ?? '',
      'totalCopies': int.tryParse(_totalCopies.text) ?? 1,
      'description': _description.text.trim(),
    };

    try {
      final service = ref.read(bookRemoteServiceProvider);
      final String savedBookId;
      if (_isEditing) {
        final updated = await service.update(widget.bookId!, payload);
        savedBookId = updated.id;
      } else {
        final created = await service.create(payload);
        savedBookId = created.id;
      }
      await _uploadCoverIfNeeded(savedBookId);
      ref.read(bookSearchControllerProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Book updated' : 'Book added successfully')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Book' : 'Add New Book')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Book' : 'Add New Book')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            if (_loadError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Text(_loadError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            _label('Book Cover'),
            InkWell(
              onTap: _uploadingCover ? null : _pickCover,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 110,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                ),
                child: _buildCoverPreview(),
              ),
            ),
            const SizedBox(height: 16),
            _field('Book Title', _title, required: true),
            _field('Author', _author, required: true),
            _field('Publisher', _publisher),
            _field('ISBN', _isbn, required: true, keyboardType: TextInputType.number),
            _field('Edition', _edition),
            _label('Category'),
            _dropdown(_category, AppConstants.categories, (v) => setState(() => _category = v!)),
            const SizedBox(height: 14),
            _label('Department'),
            _dropdown(_department, AppConstants.departments, (v) => setState(() => _department = v!)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _field('Rack No.', _rack)),
                const SizedBox(width: 12),
                Expanded(child: _field('Shelf No.', _shelf)),
              ],
            ),
            _label('Regulation'),
            DropdownButtonFormField<String>(
              initialValue: _regulation,
              isExpanded: true,
              hint: const Text('Select regulation (e.g. R2023)', overflow: TextOverflow.ellipsis, maxLines: 1),
              items: [for (final r in AppConstants.regulations) DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _regulation = v),
            ),
            const SizedBox(height: 14),
            _field('Total Copies', _totalCopies, required: true, keyboardType: TextInputType.number),
            _field('Book Description', _description, maxLines: 4),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                      : const Text('Save Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    if (_uploadingCover) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.4));
    }
    if (_pickedCoverBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_pickedCoverBytes!, fit: BoxFit.cover),
          _coverEditBadge(),
        ],
      );
    }
    final resolvedUrl = _existingCoverUrl == null ? null : ApiClient.instance.resolveFileUrl(_existingCoverUrl);
    if (resolvedUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverPlaceholder(),
          ),
          _coverEditBadge(),
        ],
      );
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, color: AppColors.textSecondary, size: 28),
        const SizedBox(height: 6),
        Text('Upload Book Cover', style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _coverEditBadge() {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.edit, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _field(String label, TextEditingController controller, {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
      onChanged: onChanged,
    );
  }
}
