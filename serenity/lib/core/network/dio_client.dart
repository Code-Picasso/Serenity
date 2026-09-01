import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/session_store.dart';

/// A single configured [Dio] instance shared across the app.
/// Adds the bearer token automatically and normalises errors.
final class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  late final Dio dio = _build();

  Dio _build() {
    final client = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 25),
        headers: const {'Accept': 'application/json'},
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionStore.instance.accessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return client;
  }
}
