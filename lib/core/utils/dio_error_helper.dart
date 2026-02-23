import 'package:dio/dio.dart';

/// Shared helper to turn [DioException] into a user-facing message.
/// Use in repositories instead of duplicating _handleError logic.
String dioErrorMessage(DioException e) {
  if (e.response?.data != null && e.response?.data['message'] != null) {
    return e.response!.data['message'] as String;
  }
  if (e.response?.statusCode != null) {
    switch (e.response!.statusCode) {
      case 404:
        return 'Not found';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Access denied';
      case 400:
        return 'Invalid request';
    }
  }
  if (e.type == DioExceptionType.connectionTimeout) {
    return 'Connection timeout';
  }
  if (e.type == DioExceptionType.receiveTimeout) {
    return 'Receive timeout';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'No internet connection';
  }
  return e.message ?? 'Unknown error occurred';
}
