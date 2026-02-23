// lib/shared/data/repositories/notification_repository.dart

import 'dart:developer';

import 'package:baatkaro/core/utils/dio_error_helper.dart';
import 'package:dio/dio.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  // Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get('/api/notifications/settings');
      log('Notification Settings Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Update notification settings
  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? enabled,
    bool? messageNotifications,
    bool? soundEnabled,
  }) async {
    try {
      final response = await _dio.put(
        '/api/notifications/settings',
        data: {
          if (enabled != null) 'enabled': enabled,
          if (messageNotifications != null)
            'messageNotifications': messageNotifications,
          if (soundEnabled != null) 'soundEnabled': soundEnabled,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

}
