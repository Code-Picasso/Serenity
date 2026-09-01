import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../widgets/article_card.dart';
import '../../widgets/post_card.dart';
import '../feed/providers/feed_providers.dart';
import 'providers/post_providers.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(savedArticlesProvider);
    final posts = ref.watch(savedPostsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ListView(
        children: [
          _SectionTitle('Articles'),
          ...articles.maybeWhen(
            data: (items) => items.isEmpty
                ? [const Padding(padding: EdgeInsets.all(16), child: Text('No saved articles.'))]
                : items.map((a) => ArticleCard(article: a)).toList(),
            orElse: () => const [SizedBox.shrink()],
          ),
          const SizedBox(height: 8),
          _SectionTitle('Posts'),
          ...posts.maybeWhen(
            data: (items) => items.isEmpty
                ? [const Padding(padding: EdgeInsets.all(16), child: Text('No saved posts.'))]
                : items.map((p) => PostCard(post: p)).toList(),
            orElse: () => const [SizedBox.shrink()],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(text, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
