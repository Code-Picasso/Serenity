import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/article_card.dart';
import 'providers/feed_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final catalog = ref.watch(topicsProvider);
    final selected = ref.watch(feedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('For you'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push(AppRoutes.createPost),
          ),
        ],
      ),
      body: Column(
        children: [
          catalog.maybeWhen(
            data: (c) => SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: selected == null,
                    onSelected: () => ref.read(feedCategoryProvider.notifier).state = null,
                  ),
                  ...c.topics.map(
                    (t) => _FilterChip(
                      label: t,
                      selected: selected == t,
                      onSelected: () => ref.read(feedCategoryProvider.notifier).state = t,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(feedProvider.future),
              child: feed.when(
                data: (articles) => articles.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No content yet. Pull to refresh.')),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: articles.length,
                        itemBuilder: (_, i) => ArticleCard(
                          article: articles[i],
                          onTap: () => context.push(AppRoutes.readArticle, arguments: articles[i]),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(feedProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
