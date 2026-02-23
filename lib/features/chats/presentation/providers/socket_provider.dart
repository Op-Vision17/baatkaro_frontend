// features/chats/presentation/providers/socket_provider.dart
// ✅ FIXED: Works with new stream-based SocketRepository

import 'dart:async';
import 'package:baatkaro/core/constants/app_constants.dart';
import 'package:baatkaro/features/chats/data/models/message_model.dart';
import 'package:baatkaro/features/chats/data/repositories/socket_repository.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socketRepositoryProvider = Provider<SocketRepository>((ref) {
  return SocketRepository();
});

// Socket State
class SocketState {
  final bool isConnected;
  final Set<String> onlineUsers;
  final List<TypingUser> typingUsers;
  final String? error;

  SocketState({
    this.isConnected = false,
    this.onlineUsers = const {},
    this.typingUsers = const [],
    this.error,
  });

  SocketState copyWith({
    bool? isConnected,
    Set<String>? onlineUsers,
    List<TypingUser>? typingUsers,
    String? error,
  }) {
    return SocketState(
      isConnected: isConnected ?? this.isConnected,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
      error: error,
    );
  }
}

// Socket Controller
class SocketController extends StateNotifier<SocketState> {
  final SocketRepository _repository;
  final Ref _ref;
  bool _isDisposed = false;

  // ✅ Stream subscriptions for typing and online users
  StreamSubscription<List<Map<String, dynamic>>>? _typingSubscription;
  StreamSubscription<List<String>>? _onlineUsersSubscription;

  SocketController(this._repository, this._ref) : super(SocketState()) {
    _setupGlobalSubscriptions();
  }

  // ✅ Setup subscriptions for global events (typing, online users)
  void _setupGlobalSubscriptions() {
    print('📡 Setting up global socket subscriptions');

    // Subscribe to typing updates
    _typingSubscription = _repository.typingStream.listen(
      (typingUsersData) {
        if (_isDisposed) return;
        print('⌨️ Typing users updated: ${typingUsersData.length} users');
        final typingUsers = typingUsersData
            .map((data) => TypingUser.fromJson(data))
            .toList();
        state = state.copyWith(typingUsers: typingUsers);
      },
      onError: (error) {
        print('❌ Typing stream error: $error');
      },
    );

    // Subscribe to online users
    _onlineUsersSubscription = _repository.onlineUsersStream.listen(
      (users) {
        if (_isDisposed) return;
        print('👥 Online users updated: ${users.length} users');
        state = state.copyWith(onlineUsers: users.toSet());
      },
      onError: (error) {
        print('❌ Online users stream error: $error');
      },
    );

    print('✅ Global subscriptions setup complete');
  }

  Future<void> connect() async {
    if (_isDisposed || state.isConnected) {
      print('⏭️ Socket already connected or disposed');
      return;
    }

    try {
      print('🔌 Connecting to socket...');

      // Get token
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final token = prefs.getString(AppConstants.accessTokenKey);

      if (token == null) {
        print('❌ No access token found');
        if (_isDisposed) return;
        state = state.copyWith(error: 'No token found');
        return;
      }

      print('✅ Token found, connecting socket...');

      // Connect with token
      await _repository.connect(token);

      if (_isDisposed) return;
      state = state.copyWith(isConnected: true);
      print('✅ Socket connected successfully');
    } catch (e) {
      print('❌ Socket connection error: $e');
      if (_isDisposed) return;
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> ensureConnected() async {
    if (_isDisposed) return;

    print('🔍 Checking socket connection...');
    print('   State connected: ${state.isConnected}');
    print('   Repository connected: ${_repository.isConnected}');

    if (_repository.isConnected && !state.isConnected) {
      state = state.copyWith(isConnected: true);
      print('✅ State updated to connected');
      return;
    }

    if (!_repository.isConnected) {
      print('⚠️ Socket not connected, reconnecting...');

      try {
        await _repository.ensureConnected();
        state = state.copyWith(isConnected: _repository.isConnected);
        print('✅ Reconnection complete: ${state.isConnected}');
      } catch (e) {
        print('❌ Reconnection failed, trying full connect: $e');
        await connect();
      }
    }

    print('✅ Socket connection check complete: ${state.isConnected}');
  }

  void joinRoom(String roomId) {
    if (_isDisposed) return;
    print('📍 Joining room: $roomId');
    _repository.joinRoom(roomId);
  }

  Future<void> sendMessage(
    String roomId,
    String text, {
    String? imageUrl,
    String? voiceUrl,
    int? voiceDuration,
  }) async {
    if (_isDisposed) return;

    print('📤 Sending message...');
    print('   Room: $roomId');

    try {
      await _repository.sendMessage(
        roomId,
        text,
        imageUrl: imageUrl,
        voiceUrl: voiceUrl,
        voiceDuration: voiceDuration,
      );
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Failed to send message: $e');
      rethrow;
    }
  }

  void deleteMessage(String messageId, String roomId) {
    if (_isDisposed) return;

    print('🗑️ Deleting message: $messageId');

    try {
      _repository.deleteMessage(messageId, roomId);
      print('✅ Delete message request sent');
    } catch (e) {
      print('❌ Failed to delete message: $e');
      rethrow;
    }
  }

  void sendTypingStatus(String roomId, bool isTyping) {
    if (_isDisposed) return;
    _repository.sendTypingStatus(roomId, isTyping);
  }

  void disconnect() {
    if (_isDisposed) return;
    print('🔌 Disconnecting socket');
    _repository.disconnect();
    state = SocketState();
  }

  @override
  void dispose() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗑️ Disposing SocketController');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _isDisposed = true;

    // Cancel stream subscriptions
    _typingSubscription?.cancel();
    _onlineUsersSubscription?.cancel();

    _repository.disconnect();

    print('✅ SocketController disposed');
    super.dispose();
  }
}

final socketControllerProvider =
    StateNotifierProvider<SocketController, SocketState>((ref) {
      final repository = ref.watch(socketRepositoryProvider);
      return SocketController(repository, ref);
    });
