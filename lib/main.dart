import 'package:baatkaro/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ ADD THIS
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'shared/services/notification_service.dart';

// ✅ ADD THIS FUNCTION (top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("📩 Background message received: ${message.messageId}");
  print("   Title: ${message.notification?.title}");
  print("   Body: ${message.notification?.body}");
  print("   Data: ${message.data}");

  if (message.data['type'] == 'incoming_call') {
    print(
      '📞 Call notification received in background - app will handle on open',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Initializing app...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // ✅ ADD THIS LINE
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background message handler registered');

    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification service initialized');
  } catch (e, stackTrace) {
    print('❌ Error during initialization: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baatkaro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(),
    );
  }
}
