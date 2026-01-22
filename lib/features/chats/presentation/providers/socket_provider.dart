// features/chats/presentation/providers/socket_provider.dart

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

  SocketController(this._repository, this._ref) : super(SocketState());

  Future<void> connect() async {
    if (_isDisposed || state.isConnected) {
      print('⏭️ Socket already connected or disposed');
      return;
    }

    try {
      print('🔌 Connecting to socket...');

      // ✅ Get token
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

      // Listen for online users
      _repository.onOnlineUsers((users) {
        print('👥 Online users updated: ${users.length} users');
        if (!_isDisposed) {
          state = state.copyWith(onlineUsers: users.toSet());
        }
      });

      // Listen for typing updates
      _repository.onTypingUpdate((typingUsersData) {
        print('⌨️ Typing users updated: ${typingUsersData.length} users');
        if (!_isDisposed) {
          final typingUsers = typingUsersData
              .map((data) => TypingUser.fromJson(data))
              .toList();
          state = state.copyWith(typingUsers: typingUsers);
        }
      });

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
    print('   Text: $text');
    print('   Image: $imageUrl');
    print('   Voice: $voiceUrl');

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

  // ✅ NEW: Delete message
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

  // ✅ NEW: Send typing status
  void sendTypingStatus(String roomId, bool isTyping) {
    if (_isDisposed) return;
    _repository.sendTypingStatus(roomId, isTyping);
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    if (_isDisposed) return;
    print('👂 Setting up message receiver');
    _repository.onReceiveMessage((data) {
      if (!_isDisposed) {
        callback(data);
      }
    });
  }

  // ✅ NEW: Listen for message deleted
  void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    if (_isDisposed) return;
    print('👂 Setting up message deleted receiver');
    _repository.onMessageDeleted((data) {
      if (!_isDisposed) {
        callback(data);
      }
    });
  }

  void onMessageUpdated(Function(Map<String, dynamic>) callback) {
    if (_isDisposed) return;
    print('👂 Setting up message updated receiver');
    _repository.onMessageUpdated((data) {
      if (!_isDisposed) {
        callback(data);
      }
    });
  }

  void disconnect() {
    if (_isDisposed) return;
    print('🔌 Disconnecting socket');
    _repository.disconnect();
    state = SocketState();
  }

  @override
  void dispose() {
    print('🗑️ Disposing socket controller');
    _isDisposed = true;
    _repository.disconnect();
    super.dispose();
  }
}

final socketControllerProvider =
    StateNotifierProvider<SocketController, SocketState>((ref) {
      final repository = ref.watch(socketRepositoryProvider);
      return SocketController(repository, ref);
    });
