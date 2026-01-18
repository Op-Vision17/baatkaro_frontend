// lib/shared/services/app_lifecycle_manager.dart
// ✅ Handles app foreground/background transitions and socket reconnection

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_providers.dart';
import '../../features/chats/presentation/providers/socket_provider.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  final Ref _ref;
  AppLifecycleState? _lastState;
  DateTime? _backgroundTime;

  AppLifecycleManager(this._ref);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    print('✅ AppLifecycleManager initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print('🗑️ AppLifecycleManager disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 App lifecycle changed: $_lastState → $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        print('⏸️ App inactive (transitioning)');
        break;
      case AppLifecycleState.detached:
        print('🔌 App detached');
        break;
      case AppLifecycleState.hidden:
        print('👁️ App hidden');
        break;
    }

    _lastState = state;
  }

  Future<void> _handleAppResumed() async {
    print('🟢 App resumed (came to foreground)');

    try {
      // Calculate time spent in background
      if (_backgroundTime != null) {
        final backgroundDuration = DateTime.now().difference(_backgroundTime!);
        print('⏱️ Was in background for: ${backgroundDuration.inSeconds}s');

        // If in background for more than 5 seconds, force reconnect
        if (backgroundDuration.inSeconds > 5) {
          print('🔄 Background duration > 5s, forcing socket reconnect...');
          await _reconnectSocket();
        } else {
          // Just ensure connection is still alive
          print('🔍 Quick background, checking socket connection...');
          await _ensureSocketConnected();
        }
      } else {
        // First resume, just ensure connection
        await _ensureSocketConnected();
      }

      _backgroundTime = null;
    } catch (e) {
      print('❌ Error handling app resume: $e');
    }
  }

  void _handleAppPaused() {
    print('🔴 App paused (went to background)');
    _backgroundTime = DateTime.now();
    
    // Don't disconnect socket - let it stay connected in background
    // Modern apps maintain socket connections in background for notifications
    print('ℹ️ Socket stays connected in background');
  }

  Future<void> _ensureSocketConnected() async {
    try {
      final authStatus = await _ref.read(authStateProvider.future);
      
      if (authStatus != AuthStatus.authenticated) {
        print('⏭️ User not authenticated, skipping socket check');
        return;
      }

      final socketController = _ref.read(socketControllerProvider.notifier);
      await socketController.ensureConnected();
      
      print('✅ Socket connection verified');
    } catch (e) {
      print('⚠️ Error ensuring socket connection: $e');
      // Try full reconnect if verification fails
      await _reconnectSocket();
    }
  }

  Future<void> _reconnectSocket() async {
    try {
      print('🔄 Starting socket reconnection...');

      final authStatus = await _ref.read(authStateProvider.future);
      
      if (authStatus != AuthStatus.authenticated) {
        print('⏭️ User not authenticated, skipping reconnection');
        return;
      }

      final socketController = _ref.read(socketControllerProvider.notifier);
      
      // Disconnect old connection
      socketController.disconnect();
      await Future.delayed(Duration(milliseconds: 500));
      
      // Establish new connection
      await socketController.connect();
      
      print('✅ Socket reconnected successfully');
    } catch (e) {
      print('❌ Failed to reconnect socket: $e');
    }
  }
}

// Provider for App Lifecycle Manager
final appLifecycleManagerProvider = Provider<AppLifecycleManager>((ref) {
  final manager = AppLifecycleManager(ref);
  manager.initialize();
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});