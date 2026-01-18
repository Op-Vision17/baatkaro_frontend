// lib/shared/services/notification_service.dart
// ✅ COMPLETE & CORRECT - No duplicate background handler

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callbacks
  Function(String roomId)? onNotificationTapped;
  Function(Map<String, dynamic> callData)? onIncomingCall; // ✅ ADD THIS

  /// Initialize notification service
  Future<void> initialize() async {
    print("🔔 Initializing NotificationService...");

    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      print("✅ NotificationService initialized successfully");
    } catch (e) {
      print("❌ Error initializing NotificationService: $e");
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ Provisional notification permission granted');
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
    }
  }

  /// Initialize local notifications for foreground handling
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
            'ic_stat_logo_for_baat_karo_chat_application_1',
          );

      // iOS settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      print("✅ Local notifications initialized");
    } catch (e) {
      print("❌ Error initializing local notifications: $e");
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print("🔑 FCM Token: $_fcmToken");

      if (_fcmToken != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("🔄 FCM Token refreshed: $newToken");
        _fcmToken = newToken;

        // Save new token and notify app to re-register
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('fcm_token', newToken);
          prefs.setBool('fcm_token_needs_registration', true);
        });
      });
    } catch (e) {
      print("❌ Error getting FCM token: $e");
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // ❌ REMOVED: Don't register background handler here (it's in main.dart)
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When app is opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from terminated state
    _checkInitialMessage();
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("📱 Foreground message received");
    print("   Title: ${message.notification?.title}");
    print("   Body: ${message.notification?.body}");
    print("   Data: ${message.data}");

    // ✅ Handle incoming call notification (don't show local notification)
    if (message.data['type'] == 'incoming_call') {
      print('📞 Incoming call notification received (foreground)');
      print('   Socket will handle showing incoming call screen');

      // Trigger callback if set (for immediate UI update)
      if (onIncomingCall != null) {
        print('   Triggering onIncomingCall callback');
        onIncomingCall!(message.data);
      }

      return; // Don't show local notification
    }

    // Show local notification for chat messages
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: 'ic_stat_logo_for_baat_karo_chat_application_1',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? 'You have a new message',
        details,
        payload: json.encode(message.data),
      );
    } catch (e) {
      print("❌ Error showing local notification: $e");
    }
  }

  /// Handle notification tap (from local notification)
  void _onNotificationTapped(NotificationResponse response) {
    print("🔔 Notification tapped");

    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);

        // ✅ Handle call notification tap
        if (data['type'] == 'incoming_call' && onIncomingCall != null) {
          print('📞 Call notification tapped');
          onIncomingCall!(data);
          return;
        }

        // Handle chat message tap
        final roomId = data['roomId'];
        if (roomId != null && onNotificationTapped != null) {
          print("   Opening room: $roomId");
          onNotificationTapped!(roomId);
        }
      }
    } catch (e) {
      print("❌ Error handling notification tap: $e");
    }
  }

  /// Handle message opened app (from background/terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print("📱 Message opened app (from background/terminated)");
    print("   Data: ${message.data}");

    // ✅ Handle call notification tap
    if (message.data['type'] == 'incoming_call') {
      print('📞 App opened from call notification');

      if (onIncomingCall != null) {
        // Small delay to let UI settle
        print('   Triggering onIncomingCall callback (delayed)');
        Future.delayed(Duration(milliseconds: 500), () {
          onIncomingCall!(message.data);
        });
      }
      return;
    }

    // ✅ Handle missed call notification
    if (message.data['type'] == 'missed_call') {
      print('📵 App opened from missed call notification');
      // Could navigate to call history or room
      return;
    }

    // Handle chat message tap
    final roomId = message.data['roomId'];
    if (roomId != null && onNotificationTapped != null) {
      onNotificationTapped!(roomId);
    }
  }

  /// Check if app was opened from terminated state
  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();

      if (initialMessage != null) {
        print("📱 App opened from terminated state by notification");
        print("   Data: ${initialMessage.data}");

        // Wait for UI to be ready
        await Future.delayed(Duration(seconds: 1));

        // ✅ Handle call notification
        if (initialMessage.data['type'] == 'incoming_call') {
          print('📞 App opened from call notification (terminated)');
          if (onIncomingCall != null) {
            print('   Triggering onIncomingCall callback');
            onIncomingCall!(initialMessage.data);
          }
          return;
        }

        // Handle chat message
        final roomId = initialMessage.data['roomId'];
        if (roomId != null && onNotificationTapped != null) {
          onNotificationTapped!(roomId);
        }
      }
    } catch (e) {
      print("❌ Error checking initial message: $e");
    }
  }

  /// Get stored FCM token
  static Future<String?> getStoredFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print("❌ Error getting stored FCM token: $e");
      return null;
    }
  }

  /// Check if token needs registration
  static Future<bool> needsTokenRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('fcm_token_needs_registration') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Clear token registration flag (for retry)
  static Future<void> clearTokenRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token_needs_registration');
      print('🔄 Token registration flag cleared');
    } catch (e) {
      print("❌ Error clearing token registration flag: $e");
    }
  }

  /// Mark token as registered
  static Future<void> markTokenAsRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fcm_token_needs_registration', false);
    } catch (e) {
      print("❌ Error marking token as registered: $e");
    }
  }
}
