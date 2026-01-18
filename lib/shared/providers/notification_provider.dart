// lib/shared/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import 'shared_providers.dart';

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// FCM Token Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.fcmToken;
});

// Register FCM Token with Backend

final registerFcmTokenProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    // Get FCM token
    final fcmToken = await NotificationService.getStoredFcmToken();

    if (fcmToken == null) {
      print('⚠️ No FCM token available');
      return false;
    }

    print(
      '🔔 Attempting to register FCM token: ${fcmToken.substring(0, 20)}...',
    );

    // Get auth repository
    final dio = ref.watch(dioProvider);
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final authRepo = AuthRepository(dio, prefs);

    // Register token with backend (ALWAYS try, don't check needsRegistration)
    final response = await authRepo.registerFcmToken(fcmToken, 'android');

    print('🔔 Register response: $response');

    if (response['success'] == true) {
      print('✅ FCM token registered with backend');
      await NotificationService.markTokenAsRegistered();
      return true;
    } else {
      print('❌ Failed to register FCM token: ${response['message']}');
      // Clear the registration flag so we try again next time
      await NotificationService.clearTokenRegistration();
      return false;
    }
  } catch (e) {
    print('❌ Error registering FCM token: $e');
    // Clear the registration flag so we try again next time
    await NotificationService.clearTokenRegistration();
    return false;
  }
});

// Notification State
class NotificationState {
  final bool isInitialized;
  final String? fcmToken;
  final String? error;

  NotificationState({this.isInitialized = false, this.fcmToken, this.error});

  NotificationState copyWith({
    bool? isInitialized,
    String? fcmToken,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      fcmToken: fcmToken ?? this.fcmToken,
      error: error,
    );
  }
}

// Notification Controller
class NotificationController extends StateNotifier<NotificationState> {
  final Ref _ref;

  NotificationController(this._ref) : super(NotificationState());

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      print('🔔 NotificationController: Initializing...');

      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.initialize();

      final token = notificationService.fcmToken;

      state = state.copyWith(isInitialized: true, fcmToken: token);

      print(
        '✅ NotificationController: Initialized with token: ${token?.substring(0, 20)}...',
      );

      // Trigger token registration
      if (token != null) {
        _ref.invalidate(registerFcmTokenProvider);
      }
    } catch (e) {
      print('❌ NotificationController: Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Register FCM token with backend
  Future<bool> registerToken() async {
    try {
      final result = await _ref.read(registerFcmTokenProvider.future);
      return result;
    } catch (e) {
      print('❌ Error in registerToken: $e');
      return false;
    }
  }

  /// Set notification tap callback
  void setOnNotificationTapped(Function(String roomId) callback) {
    final notificationService = _ref.read(notificationServiceProvider);
    notificationService.onNotificationTapped = callback;
  }
}

// Notification Controller Provider
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
      return NotificationController(ref);
    });
