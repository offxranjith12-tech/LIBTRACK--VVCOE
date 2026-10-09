import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_client.dart';
import '../models/book.dart';
import 'status_badge.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onIssue;
  /// Whether the signed-in role is allowed to edit/delete/issue this book
  /// (Admin/Librarian). Defaults to true so existing call sites keep working;
  /// screens that know the role should pass it explicitly. Matches the
  /// backend's book-write and issue/return role restrictions.
  final bool canManage;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onIssue,
    this.canManage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = book.availableCopies > 0;

    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCoverThumb(coverUrl: book.coverUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(
                          label: available ? 'Available' : 'Issued',
                          color: available ? AppColors.available : AppColors.issued,
                        ),
                        StatusBadge(label: book.category, color: AppColors.info),
                        StatusBadge(label: book.department, color: AppColors.textSecondary),
                        if (book.regulation.isNotEmpty) StatusBadge(label: book.regulation, color: const Color(0xFF6A1B9A)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${book.availableCopies}/${book.totalCopies} copies • ${book.location}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'view') onTap?.call();
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                  if (value == 'issue') onIssue?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  if (canManage) ...const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'issue', child: Text('Issue Book')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Book cover thumbnail: shows the uploaded cover if there is one, otherwise
/// falls back to the placeholder icon. Resolves relative `coverUrl`s (e.g.
/// `/uploads/covers/xyz.jpg`) against the configured backend host.
class _BookCoverThumb extends StatelessWidget {
  final String coverUrl;
  const _BookCoverThumb({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = coverUrl.isEmpty ? null : ApiClient.instance.resolveFileUrl(coverUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 68,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: resolvedUrl == null
            ? const Icon(Icons.menu_book_rounded, color: AppColors.primary)
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.menu_book_rounded, color: AppColors.primary),
              ),
      ),
    );
  }
}
