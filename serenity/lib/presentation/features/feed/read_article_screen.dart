import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/utils/url_utils.dart';
import '../../../data/models/article.dart';

class ReadArticleScreen extends ConsumerStatefulWidget {
  final Article article;
  const ReadArticleScreen({super.key, required this.article});

  @override
  ConsumerState<ReadArticleScreen> createState() => _ReadArticleScreenState();
}

class _ReadArticleScreenState extends ConsumerState<ReadArticleScreen> {
  late final Article _article = widget.article;

  @override
  void initState() {
    super.initState();
    _recordRead();
  }

  Future<void> _recordRead() async {
    try {
      await ref.read(feedRepositoryProvider).markRead(_article.id);
    } catch (_) {
      // best-effort activity tracking
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_article.hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: resolveUrl(_article.imageUrl),
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            _article.title,
            style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_article.author ?? _article.source, style: context.textTheme.bodySmall),
              const SizedBox(width: 8),
              Text('·', style: TextStyle(color: ext.textSecondary)),
              const SizedBox(width: 8),
              Text(timeAgo(_article.publishedAt), style: context.textTheme.bodySmall?.copyWith(color: ext.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _article.content.isNotEmpty ? _article.content : _article.description,
            style: context.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(feedRepositoryProvider).saveArticle(_article.id);
      if (mounted) context.showSnack('Article saved');
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    }
  }
}
