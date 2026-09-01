import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/profile.dart';

class ProfileResult {
  final Profile profile;
  final bool isFollowing;

  const ProfileResult({required this.profile, this.isFollowing = false});
}

class UserRemote {
  final Dio _dio = DioClient.instance.dio;

  Future<Profile> me() async {
    try {
      final res = await _dio.get('/users/me');
      return Profile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Profile> updateMe({
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    try {
      final res = await _dio.put('/users/me', data: {
        'name': ?name,
        'username': ?username,
        'bio': ?bio,
        'avatarUrl': ?avatarUrl,
        'isPublic': ?isPublic,
      });
      return Profile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProfileResult> getProfile(String userId) async {
    try {
      final res = await _dio.get('/users/$userId');
      final data = res.data as Map<String, dynamic>;
      return ProfileResult(
        profile: Profile.fromJson(data['profile'] as Map<String, dynamic>? ?? {}),
        isFollowing: data['isFollowing'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Profile>> topReaders({int limit = 20}) async {
    try {
      final res = await _dio.get('/users/top-readers', queryParameters: {'limit': limit});
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> follow(String userId) async {
    try {
      await _dio.post('/users/$userId/follow');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> unfollow(String userId) async {
    try {
      await _dio.delete('/users/$userId/follow');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Profile>> followers(String userId) async {
    try {
      final res = await _dio.get('/users/$userId/followers');
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Profile>> following(String userId) async {
    try {
      final res = await _dio.get('/users/$userId/following');
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
