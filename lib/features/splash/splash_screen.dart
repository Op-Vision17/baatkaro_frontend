import 'package:baatkaro/core/theme/app_theme.dart';
import 'package:baatkaro/features/auth/presentation/screens/login_screen.dart';
import 'package:baatkaro/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:baatkaro/features/home/presentation/screens/home_screen.dart';
import 'package:baatkaro/features/calls/presentation/provider/call_provider.dart'; // ✅ ADD
import 'package:baatkaro/features/chats/presentation/providers/socket_provider.dart'; // ✅ ADD
import 'package:baatkaro/shared/providers/notification_provider.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


Future<void> _initializeAndNavigate() async {
  try {
    print('🔄 Starting splash initialization...');

    final authStatus = await ref.read(authStateProvider.future);
    print('✅ Auth status loaded: $authStatus');

    // ✅ FIX: Refresh token BEFORE connecting socket
    if (authStatus == AuthStatus.authenticated) {
      try {
        print('🔄 Refreshing token before socket connection...');
        
        // ✅ Make a simple API call to trigger token refresh if needed
        final dio = ref.read(dioProvider);
        
        try {
          // This will automatically refresh the token if it's expired
          await dio.get('/api/auth/profile');
          print('✅ Token verified/refreshed');
        } catch (e) {
          print('⚠️ Token verification failed: $e');
          // If profile call fails, token might be completely invalid
          // Let the auth flow handle it
        }

        print('🔌 Initializing socket + call listeners...');

        // ✅ Now get the fresh token
        final prefs = await ref.read(sharedPreferencesProvider.future);
        final token = prefs.getString('access_token');
        
        if (token == null) {
          print('❌ No token found after refresh');
          throw Exception('No token available');
        }

        print('✅ Fresh token available, connecting socket...');

        // Connect socket with fresh token
        await ref.read(socketControllerProvider.notifier).connect();
        print('✅ Socket connected');

        // Initialize call provider (this sets up listeners)
        ref.read(callControllerProvider);
        print('✅ Call listeners initialized');

        // Register FCM token
        print('🔔 Registering FCM token...');
        await ref
            .read(notificationControllerProvider.notifier)
            .registerToken();
        print('✅ FCM token registered');
      } catch (e, stackTrace) {
        print('⚠️ Failed to initialize socket/calls: $e');
        print('Stack trace: $stackTrace');
        // Don't block navigation - socket can reconnect later
      }
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted || _hasNavigated) {
      print('⚠️ Navigation cancelled - widget disposed or already navigated');
      return;
    }

    _hasNavigated = true;

    Widget destination;
    String destinationName;

    if (authStatus == AuthStatus.authenticated) {
      destination = HomeScreen();
      destinationName = 'HomeScreen';
    } else if (authStatus == AuthStatus.needsOnboarding) {
      destination = OnboardingScreen();
      destinationName = 'OnboardingScreen';
    } else {
      destination = LoginScreen();
      destinationName = 'LoginScreen';
    }

    print('🚀 Navigating to $destinationName...');

    if (mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
      print('✅ Navigation completed');
    }
  } catch (e, stackTrace) {
    print('❌ Error during splash initialization: $e');
    print('Stack trace: $stackTrace');

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    if (mounted) {
      print('🚀 Navigating to LoginScreen (fallback after error)...');
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryYellow,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/app_logo.png',
                    width: 180,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlack.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppTheme.primaryBlack,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s Talk!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.white.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
