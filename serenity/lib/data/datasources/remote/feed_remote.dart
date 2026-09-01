import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/article.dart';
import '../../models/paginated.dart';
import '../../models/topic.dart';

class FeedRemote {
  final Dio _dio = DioClient.instance.dio;

  Future<Paginated<Article>> getFeed({int page = 1, int limit = 20, String? topic}) async {
    try {
      final res = await _dio.get('/feed', queryParameters: {
        'page': page,
        'limit': limit,
        if (topic != null && topic.isNotEmpty) 'topic': topic,
      });
      return Paginated.fromJson(res.data as Map<String, dynamic>, Article.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Article> getArticle(String id) async {
    try {
      final res = await _dio.get('/feed/articles/$id');
      return Article.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post('/feed/articles/$id/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Paginated<Article>> search(String query, {int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/feed/search', queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      });
      return Paginated.fromJson(res.data as Map<String, dynamic>, Article.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<TopicCatalog> topics() async {
    try {
      final res = await _dio.get('/feed/topics');
      return TopicCatalog.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<String>> getInterests() async {
    try {
      final res = await _dio.get('/feed/interests');
      return ((res.data as Map<String, dynamic>)['topics'] as List<dynamic>? ?? [])
          .cast<String>();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> saveInterests(List<String> topics) async {
    try {
      await _dio.put('/feed/interests', data: {'topics': topics});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> saveArticle(String id) async {
    try {
      await _dio.post('/feed/articles/$id/save');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> unsaveArticle(String id) async {
    try {
      await _dio.delete('/feed/articles/$id/save');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Article>> savedArticles() async {
    try {
      final res = await _dio.get('/feed/saved');
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
