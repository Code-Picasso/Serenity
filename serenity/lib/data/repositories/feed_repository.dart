import '../datasources/remote/feed_remote.dart';
import '../models/article.dart';
import '../models/paginated.dart';
import '../models/topic.dart';

class FeedRepository {
  final FeedRemote _remote;

  FeedRepository(this._remote);

  Future<Paginated<Article>> getFeed({int page = 1, int limit = 20, String? topic}) =>
      _remote.getFeed(page: page, limit: limit, topic: topic);

  Future<Article> getArticle(String id) => _remote.getArticle(id);

  Future<void> markRead(String id) => _remote.markRead(id);

  Future<Paginated<Article>> search(String query, {int page = 1}) =>
      _remote.search(query, page: page);

  Future<TopicCatalog> topics() => _remote.topics();

  Future<List<String>> getInterests() => _remote.getInterests();

  Future<void> saveInterests(List<String> topics) => _remote.saveInterests(topics);

  Future<void> saveArticle(String id) => _remote.saveArticle(id);

  Future<void> unsaveArticle(String id) => _remote.unsaveArticle(id);

  Future<List<Article>> savedArticles() => _remote.savedArticles();
}
