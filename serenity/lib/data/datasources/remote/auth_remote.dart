import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/user.dart';

class AuthRemote {
  final Dio _dio = DioClient.instance.dio;

  Future<AuthResult> register({
    required String username,
    required String password,
    required String name,
    required String gender,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'name': name,
        'gender': gender,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthResult> login({required String username, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {'username': username, 'password': password});
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthResult> refresh(String refreshToken) async {
    try {
      final res = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<User> me() async {
    try {
      final res = await _dio.get('/auth/me');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
