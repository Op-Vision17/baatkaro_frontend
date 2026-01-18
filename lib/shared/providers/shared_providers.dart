import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Dio Provider with Token Refresh Interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
    ),
  );

  // Add interceptor for automatic token handling and refresh
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await ref.read(sharedPreferencesProvider.future);
        final token = prefs.getString(AppConstants.accessTokenKey);

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        // If 401 and we have a refresh token, try to refresh
        if (error.response?.statusCode == 401) {
          final errorCode = error.response?.data?['code'];

          if (errorCode == 'TOKEN_EXPIRED') {
            try {
              final prefs = await ref.read(sharedPreferencesProvider.future);
              final authRepo = AuthRepository(dio, prefs);

              // Try to refresh the token
              final newAccessToken = await authRepo.refreshAccessToken();

              // Retry the original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';

              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              // Refresh failed, invalidate auth
              ref.invalidate(authStateProvider);
              return handler.reject(error);
            }
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
});

// Auth State Provider - checks authentication status
final authStateProvider = FutureProvider<AuthStatus>((ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  final accessToken = prefs.getString(AppConstants.accessTokenKey);
  final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
  final needsOnboarding =
      prefs.getBool(AppConstants.needsOnboardingKey) ?? false;

  if (accessToken == null || refreshToken == null) {
    return AuthStatus.unauthenticated;
  }

  if (needsOnboarding) {
    return AuthStatus.needsOnboarding;
  }

  return AuthStatus.authenticated;
});

// Auth Status Enum
enum AuthStatus { authenticated, unauthenticated, needsOnboarding }

// Current User ID Provider
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getString(AppConstants.userIdKey);
});

// Current User Name Provider
final currentUserNameProvider = FutureProvider<String?>((ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getString(AppConstants.userNameKey);
});

// Current User Email Provider
final currentUserEmailProvider = FutureProvider<String?>((ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getString(AppConstants.userEmailKey);
});
