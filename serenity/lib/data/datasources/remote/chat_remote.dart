import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/conversation.dart';

class ChatRemote {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Conversation>> conversations() async {
    try {
      final res = await _dio.get('/chat/conversations');
      return (res.data as List<dynamic>? ?? [])
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<String> createConversation(String userId) async {
    try {
      final res = await _dio.post('/chat/conversations', data: {'userId': userId});
      return (res.data as Map<String, dynamic>)['id'] as String? ?? '';
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Conversation> getConversation(String id) async {
    try {
      final res = await _dio.get('/chat/conversations/$id');
      return Conversation.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Message>> messages(String id, {int page = 1, int limit = 50}) async {
    try {
      final res = await _dio.get('/chat/conversations/$id/messages', queryParameters: {
        'page': page,
        'limit': limit,
      });
      return ((res.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [])
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Message> sendText(String id, String content) async {
    try {
      final res = await _dio.post('/chat/conversations/$id/messages', data: {
        'type': 'text',
        'content': content,
      });
      return Message.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Message> sendAudio(String id, File audio) async {
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audio.path),
      });
      final res = await _dio.post('/chat/conversations/$id/messages/audio', data: form);
      return Message.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post('/chat/conversations/$id/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
