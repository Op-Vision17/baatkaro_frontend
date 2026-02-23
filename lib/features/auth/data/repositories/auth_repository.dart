// ignore_for_file: unused_catch_clause

import 'dart:io';

import 'package:baatkaro/core/utils/dio_error_helper.dart';
import 'package:baatkaro/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;

  AuthRepository(this._dio, this._prefs);

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post(
        AppConstants.sendOtpEndpoint,
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Verify OTP (just email and OTP, no name)
  Future<User> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        AppConstants.verifyOtpEndpoint,
        data: {'email': email, 'otp': otp},
      );

      final data = response.data;
      final user = User.fromJson(data);

      // Save tokens and user data
      await _saveUserData(user);

      return user;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Complete Onboarding (set name and optional profile photo)
  Future<User> completeOnboarding(String name, {String? profilePhoto}) async {
    try {
      final response = await _dio.post(
        AppConstants.completeOnboardingEndpoint,
        data: {
          'name': name,
          if (profilePhoto != null) 'profilePhoto': profilePhoto,
        },
      );

      // ignore: unused_local_variable
      final data = response.data;

      // Update stored name and photo
      await _prefs.setString(AppConstants.userNameKey, name);
      if (profilePhoto != null) {
        await _prefs.setString('profilePhoto', profilePhoto);
      }
      await _prefs.setBool(AppConstants.needsOnboardingKey, false);

      // Return updated user
      final userId = _prefs.getString(AppConstants.userIdKey) ?? '';
      final email = _prefs.getString(AppConstants.userEmailKey) ?? '';
      final accessToken = _prefs.getString(AppConstants.accessTokenKey);
      final refreshToken = _prefs.getString(AppConstants.refreshTokenKey);

      return User(
        id: userId,
        name: name,
        email: email,
        profilePhoto: profilePhoto,
        accessToken: accessToken,
        refreshToken: refreshToken,
        needsOnboarding: false,
      );
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get(AppConstants.profileEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'profilePhoto': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        AppConstants.uploadProfilePhotoEndpoint,
        data: formData,
      );

      if (response.statusCode == 200) {
        final photoUrl = response.data['profilePhotoUrl'];
        print('✅ Profile photo uploaded: $photoUrl');
        return photoUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to upload profile photo: ${dioErrorMessage(e)}');
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile(
    String name,
    String? profilePhoto,
  ) async {
    try {
      final response = await _dio.put(
        AppConstants.profileEndpoint,
        data: {
          'name': name,
          if (profilePhoto != null) 'profilePhoto': profilePhoto,
        },
      );

      // Update SharedPreferences
      await _prefs.setString(AppConstants.userNameKey, name);
      if (profilePhoto != null) {
        await _prefs.setString('profilePhoto', profilePhoto);
      }

      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Refresh Access Token
  Future<String> refreshAccessToken() async {
    try {
      final refreshToken = _prefs.getString(AppConstants.refreshTokenKey);

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _dio.post(
        AppConstants.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'];
      await _prefs.setString(AppConstants.accessTokenKey, newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      // If refresh fails, clear all data (user needs to login again)
      await logout();
      throw Exception('Session expired. Please login again.');
    }
  }

  Future<Map<String, dynamic>> registerFcmToken(
    String token,
    String device,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.registerFcmTokenEndpoint,
        data: {'token': token, 'device': device},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Remove FCM Token
  Future<Map<String, dynamic>> removeFcmToken(String token) async {
    try {
      final response = await _dio.post(
        AppConstants.unregisterFcmTokenEndpoint,
        data: {'token': token},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Get FCM token before clearing prefs
      final fcmToken = _prefs.getString('fcm_token');

      // Try to call logout endpoint with FCM token
      if (fcmToken != null) {
        await _dio.post(
          AppConstants.logoutEndpoint,
          data: {'fcmToken': fcmToken},
        );
        print('✅ Logged out with FCM token cleanup');
      } else {
        await _dio.post(AppConstants.logoutEndpoint);
        print('✅ Logged out without FCM token');
      }
    } catch (e) {
      print('⚠️ Logout API call failed: $e');
      // Ignore errors, clear local data anyway
    } finally {
      await _prefs.clear();
      print('✅ Local data cleared');
    }
  }

  // Get stored tokens
  String? getAccessToken() {
    return _prefs.getString(AppConstants.accessTokenKey);
  }

  String? getRefreshToken() {
    return _prefs.getString(AppConstants.refreshTokenKey);
  }

  // Get user data
  String? getUserId() {
    return _prefs.getString(AppConstants.userIdKey);
  }

  String? getUserName() {
    return _prefs.getString(AppConstants.userNameKey);
  }

  String? getUserEmail() {
    return _prefs.getString(AppConstants.userEmailKey);
  }

  String? getProfilePhoto() {
    return _prefs.getString('profilePhoto');
  }

  bool getNeedsOnboarding() {
    return _prefs.getBool(AppConstants.needsOnboardingKey) ?? false;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    final accessToken = getAccessToken();
    final refreshToken = getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(User user) async {
    if (user.accessToken != null) {
      await _prefs.setString(AppConstants.accessTokenKey, user.accessToken!);
    }
    if (user.refreshToken != null) {
      await _prefs.setString(AppConstants.refreshTokenKey, user.refreshToken!);
    }
    await _prefs.setString(AppConstants.userIdKey, user.id);
    await _prefs.setString(AppConstants.userEmailKey, user.email);
    await _prefs.setBool(AppConstants.needsOnboardingKey, user.needsOnboarding);

    if (user.name != null) {
      await _prefs.setString(AppConstants.userNameKey, user.name!);
    }
    if (user.profilePhoto != null) {
      await _prefs.setString('profilePhoto', user.profilePhoto!);
    }
  }

}
