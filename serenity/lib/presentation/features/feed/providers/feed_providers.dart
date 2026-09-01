import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/article.dart';
import '../../../../data/models/paginated.dart';
import '../../../../data/models/topic.dart';

final feedCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

final feedProvider = FutureProvider.autoDispose<List<Article>>((ref) async {
  final topic = ref.watch(feedCategoryProvider);
  final result = await ref.read(feedRepositoryProvider).getFeed(topic: topic);
  return result.items;
});

final topicsProvider = FutureProvider.autoDispose<TopicCatalog>((ref) async {
  return ref.read(feedRepositoryProvider).topics();
});

final interestsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(feedRepositoryProvider).getInterests();
});

final savedArticlesProvider = FutureProvider.autoDispose<List<Article>>((ref) async {
  return ref.read(feedRepositoryProvider).savedArticles();
});

final searchProvider =
    FutureProvider.autoDispose.family<Paginated<Article>, String>((ref, query) async {
  return ref.read(feedRepositoryProvider).search(query);
});
