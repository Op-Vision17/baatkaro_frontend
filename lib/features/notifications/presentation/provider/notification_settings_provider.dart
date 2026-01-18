import 'dart:developer';

import 'package:baatkaro/features/notifications/data/repositories/notification_repository.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notification Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationRepository(dio);
});

// Notification Settings Model
class NotificationSettings {
  final bool enabled;
  final bool messageNotifications;
  final bool soundEnabled;

  NotificationSettings({
    required this.enabled,
    required this.messageNotifications,
    required this.soundEnabled,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'messageNotifications': messageNotifications,
      'soundEnabled': soundEnabled,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? messageNotifications,
    bool? soundEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

// Notification Settings State
class NotificationSettingsState {
  final NotificationSettings? settings;
  final bool isLoading;
  final String? error;

  NotificationSettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
  });

  NotificationSettingsState copyWith({
    NotificationSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notification Settings Controller
class NotificationSettingsController
    extends StateNotifier<NotificationSettingsState> {
  final NotificationRepository _repository;

  NotificationSettingsController(this._repository)
    : super(NotificationSettingsState());

  // Load settings from backend
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getNotificationSettings();
      log('Loaded Notification Settings: $response');

      if (response['success'] == true) {
        final settings = NotificationSettings.fromJson(response['settings']);
        state = state.copyWith(settings: settings, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load settings',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Update a specific setting
  Future<bool> updateSetting({
    bool? enabled,
    bool? messageNotifications,
    bool? soundEnabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.updateNotificationSettings(
        enabled: enabled,
        messageNotifications: messageNotifications,
        soundEnabled: soundEnabled,
      );

      if (response['success'] == true) {
        final settings = NotificationSettings.fromJson(response['settings']);
        state = state.copyWith(settings: settings, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to update settings',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // Toggle enabled
  Future<bool> toggleEnabled(bool value) async {
    return await updateSetting(enabled: value);
  }

  // Toggle message notifications
  Future<bool> toggleMessageNotifications(bool value) async {
    return await updateSetting(messageNotifications: value);
  }

  // Toggle sound
  Future<bool> toggleSound(bool value) async {
    return await updateSetting(soundEnabled: value);
  }
}

// Notification Settings Controller Provider
final notificationSettingsControllerProvider =
    StateNotifierProvider<
      NotificationSettingsController,
      NotificationSettingsState
    >((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return NotificationSettingsController(repository);
    });
