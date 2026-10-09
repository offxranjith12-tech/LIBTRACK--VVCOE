import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: c, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const GlassAppBar({super.key, required this.title, this.actions, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Opens a full-screen profile photo viewer, similar to tapping a contact's
/// display picture in WhatsApp - dark backdrop, tap anywhere to dismiss.
/// Used from both the Dashboard header and the Profile screen's avatar.
void openPhotoViewer(BuildContext context, {required String name, required ImageProvider? image}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, animation, secondaryAnimation) => _PhotoViewerScreen(name: name, image: image),
    ),
  );
}

class _PhotoViewerScreen extends StatelessWidget {
  final String name;
  final ImageProvider? image;
  const _PhotoViewerScreen({required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(name),
        ),
        body: Center(
          child: CircleAvatar(
            radius: 120,
            backgroundColor: Colors.white24,
            backgroundImage: image,
            child: image == null
                ? Text(
                    name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 52),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
