import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/book.dart';
import '../../providers/service_providers.dart';
import '../../widgets/status_badge.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late Future<Book> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(bookRemoteServiceProvider).getById(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: FutureBuilder<Book>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load this book:\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }
          final b = snapshot.data!;
          return _BookDetailBody(book: b);
        },
      ),
    );
  }
}

class _BookDetailBody extends StatelessWidget {
  final Book book;
  const _BookDetailBody({required this.book});

  @override
  Widget build(BuildContext context) {
    final b = book;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/books/${b.id}/edit')),
        ),
        Center(
          child: Builder(builder: (context) {
            final resolvedUrl = b.coverUrl.isEmpty ? null : ApiClient.instance.resolveFileUrl(b.coverUrl);
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 120,
                height: 160,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: resolvedUrl == null
                    ? const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 48)
                    : CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        errorWidget: (_, __, ___) => const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 48),
                      ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(b.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Center(child: Text('by ${b.author}', style: TextStyle(color: AppColors.textSecondary))),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 8,
            children: [
              StatusBadge(label: b.availableCopies > 0 ? 'Available' : 'Issued', color: b.availableCopies > 0 ? AppColors.available : AppColors.issued),
              StatusBadge(label: b.category, color: AppColors.info),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DetailCard(
          children: [
            _DetailRow('Publisher', b.publisher),
            _DetailRow('ISBN', b.isbn),
            _DetailRow('Edition', b.edition),
            _DetailRow('Department', b.department),
            if (b.regulation.isNotEmpty) _DetailRow('Regulation', b.regulation),
            _DetailRow('Location', b.location),
            _DetailRow('Total Copies', '${b.totalCopies}'),
            _DetailRow('Available Copies', '${b.availableCopies}'),
            _DetailRow('Issued Copies', '${b.issuedCopies}'),
          ],
        ),
        const SizedBox(height: 16),
        if (b.description.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(b.description, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              QrImageView(data: b.qrCode, size: 140),
              const SizedBox(height: 8),
              Text(b.qrCode, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: b.availableCopies > 0 ? () => context.push('/transactions/issue?bookId=${b.id}') : null,
                icon: const Icon(Icons.output_rounded),
                label: const Text('Issue Book'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/books/${b.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Book'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
