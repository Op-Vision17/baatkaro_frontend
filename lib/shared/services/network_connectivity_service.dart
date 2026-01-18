// lib/shared/services/network_connectivity_service.dart
// ✅ Monitors network changes and triggers socket reconnection

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chats/presentation/providers/socket_provider.dart';
import '../providers/shared_providers.dart';

class NetworkConnectivityService {
  final Ref _ref;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _wasConnected = true;
  bool _isReconnecting = false;

  NetworkConnectivityService(this._ref);

  Future<void> initialize() async {
    print('🌐 Initializing Network Connectivity Service...');

    // Check initial connectivity
    final initialResult = await _connectivity.checkConnectivity();
    _wasConnected = !initialResult.contains(ConnectivityResult.none);
    
    print('📶 Initial connectivity: ${_wasConnected ? "Connected" : "Disconnected"}');

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        print('❌ Connectivity stream error: $error');
      },
    );

    print('✅ Network Connectivity Service initialized');
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    if (_isReconnecting) {
      print('⏳ Already reconnecting, skipping...');
      return;
    }

    final isConnected = !results.contains(ConnectivityResult.none);
    final connectionType = _getConnectionType(results);
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📶 Network connectivity changed');
    print('   Type: $connectionType');
    print('   Was connected: $_wasConnected');
    print('   Is connected: $isConnected');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Network restored after disconnection
    if (!_wasConnected && isConnected) {
      print('✅ Network restored! Reconnecting socket...');
      await _reconnectSocket();
    }
    // Network lost
    else if (_wasConnected && !isConnected) {
      print('❌ Network lost!');
      _handleNetworkLost();
    }
    // Network type changed (WiFi ↔ Mobile)
    else if (_wasConnected && isConnected && connectionType != 'none') {
      print('🔄 Network type changed, reconnecting socket...');
      await _reconnectSocket();
    }

    _wasConnected = isConnected;
  }

  String _getConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (results.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'none';
  }

  void _handleNetworkLost() {
    print('📴 Network disconnected');
    // Don't disconnect socket immediately - it might reconnect automatically
    // Backend will handle timeout and cleanup
  }

  Future<void> _reconnectSocket() async {
    if (_isReconnecting) return;
    
    _isReconnecting = true;
    
    try {
      print('🔄 Starting socket reconnection due to network change...');

      // Check if user is authenticated
      final authStatus = await _ref.read(authStateProvider.future);
      
      if (authStatus != AuthStatus.authenticated) {
        print('⏭️ User not authenticated, skipping socket reconnection');
        return;
      }

      final socketController = _ref.read(socketControllerProvider.notifier);
      
      // Give network a moment to stabilize
      await Future.delayed(Duration(seconds: 1));
      
      // Disconnect and reconnect
      socketController.disconnect();
      await Future.delayed(Duration(milliseconds: 500));
      
      await socketController.connect();
      
      print('✅ Socket reconnected after network change');
    } catch (e) {
      print('❌ Failed to reconnect socket after network change: $e');
    } finally {
      _isReconnecting = false;
    }
  }

  void dispose() {
    print('🗑️ Disposing Network Connectivity Service');
    _subscription?.cancel();
    _subscription = null;
  }
}

// Provider for Network Connectivity Service
final networkConnectivityServiceProvider = Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityService(ref);
  
  // Initialize asynchronously
  Future.microtask(() => service.initialize());
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});