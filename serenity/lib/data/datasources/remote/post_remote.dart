import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/paginated.dart';
import '../../models/post.dart';

class PostRemote {
  final Dio _dio = DioClient.instance.dio;

  Future<Paginated<Post>> getPosts({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/posts', queryParameters: {'page': page, 'limit': limit});
      return Paginated.fromJson(res.data as Map<String, dynamic>, Post.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final res = await _dio.get('/posts/users/$userId/posts');
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Post> createPost({String text = '', String? imageUrl}) async {
    try {
      final res = await _dio.post('/posts', data: {'text': text, 'imageUrl': imageUrl});
      return Post.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path),
      });
      final res = await _dio.post('/posts/upload', data: form);
      return (res.data as Map<String, dynamic>)['imageUrl'] as String? ?? '';
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _dio.delete('/posts/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<bool> toggleLike(String id) async {
    try {
      final res = await _dio.post('/posts/$id/like');
      return (res.data as Map<String, dynamic>)['liked'] as bool? ?? false;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Post> reshare(String id) async {
    try {
      final res = await _dio.post('/posts/$id/reshare');
      return Post.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> savePost(String id) async {
    try {
      await _dio.post('/posts/$id/save');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> unsavePost(String id) async {
    try {
      await _dio.delete('/posts/$id/save');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Post>> savedPosts() async {
    try {
      final res = await _dio.get('/posts/saved');
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Post>> resharedPosts() async {
    try {
      final res = await _dio.get('/posts/reshared');
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
