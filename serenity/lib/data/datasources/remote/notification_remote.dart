import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/notification.dart';

class NotificationRemote {
  final Dio _dio = DioClient.instance.dio;

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 50}) async {
    try {
      final res = await _dio.get('/notifications', queryParameters: {'page': page, 'limit': limit});
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      return (res.data as Map<String, dynamic>)['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/notifications/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
