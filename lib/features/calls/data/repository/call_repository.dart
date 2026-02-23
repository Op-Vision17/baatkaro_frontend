import 'package:baatkaro/core/utils/dio_error_helper.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

class CallRepository {
  final Dio _dio;

  CallRepository(this._dio);

  // ✅ NEW: Check if room has active call
  Future<Map<String, dynamic>> checkActiveCall(String roomId) async {
    try {
      print('🔍 Checking for active call in room: $roomId');

      final response = await _dio.get('/api/calls/room/$roomId/active');

      print('✅ Active call check response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Error checking active call: $e');
      throw Exception('Failed to check active call: ${dioErrorMessage(e)}');
    }
  }

  // ✅ NEW: Get all active calls in user's rooms
  Future<List<dynamic>> getMyActiveRoomCalls() async {
    try {
      print('🔍 Fetching all active calls in my rooms');

      final response = await _dio.get('/api/calls/my-rooms/active');

      final data = response.data as Map<String, dynamic>;
      final calls = data['activeCalls'] as List<dynamic>;

      print('✅ Found ${calls.length} active calls');

      return calls;
    } on DioException catch (e) {
      print('❌ Error fetching active calls: $e');
      throw Exception('Failed to fetch active calls: ${dioErrorMessage(e)}');
    }
  }

  // Generate Agora token
  Future<Map<String, dynamic>> generateAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.generateAgoraTokenEndpoint,
        data: {'channelName': channelName, 'uid': uid},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Get call history for a room
  Future<List<dynamic>> getCallHistory(String roomId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.callHistoryEndpoint}/$roomId',
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

}
