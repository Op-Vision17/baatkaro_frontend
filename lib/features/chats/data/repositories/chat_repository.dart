import 'dart:io';
import 'package:baatkaro/core/constants/app_constants.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  // Get user's rooms
  Future<List<dynamic>> getUserRooms() async {
    try {
      final response = await _dio.get(AppConstants.myRoomsEndpoint);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get rooms: ${_handleError(e)}');
    }
  }

  // Create room
  Future<Map<String, dynamic>> createRoom(
    String name, {
    String? roomPhoto,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.createRoomEndpoint,
        data: {'name': name, if (roomPhoto != null) 'roomPhoto': roomPhoto},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to create room: ${_handleError(e)}');
    }
  }

  // Update room
  Future<Map<String, dynamic>> updateRoom(
    String roomId, {
    String? name,
    String? roomPhoto,
  }) async {
    try {
      final response = await _dio.put(
        '/api/room/$roomId',
        data: {
          if (name != null) 'name': name,
          if (roomPhoto != null) 'roomPhoto': roomPhoto,
        },
      );
      return response.data['room'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to update room: ${_handleError(e)}');
    }
  }

  // Join room by code
  Future<Map<String, dynamic>> joinRoomByCode(String roomCode) async {
    try {
      final response = await _dio.post(
        AppConstants.joinRoomEndpoint,
        data: {'roomCode': roomCode},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Room not found');
      }
      throw Exception('Failed to join room: ${_handleError(e)}');
    }
  }

  // Get room details
  Future<Map<String, dynamic>> getRoomDetails(String roomId) async {
    try {
      final response = await _dio.get('/api/room/$roomId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get room details: ${_handleError(e)}');
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _dio.delete('/api/room/$roomId');
    } on DioException catch (e) {
      throw Exception('Failed to delete room: ${_handleError(e)}');
    }
  }

  // Leave room
  Future<void> leaveRoom(String roomId) async {
    try {
      await _dio.post('/api/room/$roomId/leave');
    } on DioException catch (e) {
      throw Exception('Failed to leave room: ${_handleError(e)}');
    }
  }

  // Get room messages
  Future<List<dynamic>> getRoomMessages(String roomId) async {
    try {
      final response = await _dio.get('/api/room/$roomId/messages');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get messages: ${_handleError(e)}');
    }
  }

  // Upload room photo
  Future<String> uploadRoomPhoto(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'roomPhoto': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        AppConstants.uploadRoomPhotoEndpoint,
        data: formData,
      );

      if (response.statusCode == 200) {
        final photoUrl = response.data['roomPhotoUrl'];
        print('✅ Room photo uploaded: $photoUrl');
        return photoUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to upload room photo: ${_handleError(e)}');
    }
  }

  // Upload image
  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        AppConstants.uploadImageEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.statusCode == 200) {
        final imageUrl = response.data['imageUrl'];
        print('✅ Image uploaded: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to upload image: ${_handleError(e)}');
    }
  }

  // Upload voice
  Future<Map<String, dynamic>> uploadVoice(File voiceFile) async {
    try {
      String fileName = voiceFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'voice': await MultipartFile.fromFile(
          voiceFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        AppConstants.uploadVoiceEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.statusCode == 200) {
        print('✅ Voice uploaded: ${response.data['voiceUrl']}');
        return response.data;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to upload voice: ${_handleError(e)}');
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 404) {
      return 'Not found';
    } else if (e.response?.statusCode == 401) {
      return 'Unauthorized';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout';
    }
    return e.message ?? 'Unknown error occurred';
  }
}
