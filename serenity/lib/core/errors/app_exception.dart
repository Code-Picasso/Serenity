import 'package:dio/dio.dart';

/// Base exception type thrown by repositories. Controllers/providers catch
/// these and surface a user-friendly message without leaking implementation.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const AppException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => 'AppException($statusCode): $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message) : super(statusCode: null);
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

class ValidationException extends AppException {
  const ValidationException(super.message) : super(statusCode: 400);
}

class CacheException extends AppException {
  const CacheException(super.message);
}

/// Maps a [DioException] into a typed [AppException].
AppException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('Connection timed out. Please try again.');
    case DioExceptionType.connectionError:
      return const NetworkException('Could not reach the server. Check your connection.');
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final message = extractErrorMessage(e.response?.data);
      switch (status) {
        case 400:
          return ValidationException(message ?? 'Invalid request.');
        case 401:
          return UnauthorizedException(message ?? 'Session expired. Please sign in again.');
        case 404:
          return NotFoundException(message ?? 'Resource not found.');
        case 409:
          return ValidationException(message ?? 'A record already exists.');
        case 500:
        case 502:
        case 503:
          return ServerException(message ?? 'Server error. Please try again.', statusCode: status);
        default:
          return ServerException(message ?? 'Something went wrong.', statusCode: status);
      }
    case DioExceptionType.cancel:
      return const AppException('Request cancelled.');
    case DioExceptionType.badCertificate:
      return const AppException('Invalid server certificate.');
    default:
      return const AppException('Unexpected error occurred.');
  }
}

/// Extracts a human-readable message from the backend's `{message, error}` shape.
String? extractErrorMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) return data;
  if (data is Map) {
    if (data['message'] is String) return data['message'] as String;
    if (data['error'] is String) return data['error'] as String;
  }
  return null;
}
