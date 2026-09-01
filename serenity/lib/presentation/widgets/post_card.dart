import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/widget_extensions.dart';
import '../../core/utils/time_ago.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/post.dart';
import 'user_avatar.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onReshare;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onSave,
    this.onReshare,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    return Card(
      color: ext.surfaceElevated,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const UserAvatar(name: 'User'),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.isReshare ? 'Reshared post' : 'Serenity user',
                    style: context.textTheme.titleSmall,
                  ),
                ),
                Text(
                  timeAgo(post.createdAt),
                  style: context.textTheme.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(post.text, style: context.textTheme.bodyLarge),
            ],
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: CachedNetworkImage(
                  imageUrl: resolveUrl(post.imageUrl),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    height: 160,
                    color: ext.surfaceHigh,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.favorite_border,
                  label: '${post.likeCount}',
                  onTap: onLike,
                ),
                _ActionButton(icon: Icons.repeat_rounded, label: 'Reshare', onTap: onReshare),
                _ActionButton(icon: Icons.bookmark_border_rounded, label: 'Save', onTap: onSave),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.themeExt.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: context.textTheme.bodySmall?.copyWith(color: context.themeExt.textSecondary)),
          ],
        ),
      ),
    );
  }
}
