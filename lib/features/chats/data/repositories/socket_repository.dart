// features/chats/data/repositories/socket_repository.dart
// ✅ ENHANCED: Better connection management, automatic reconnection, message queue

import 'dart:async';
import 'package:baatkaro/core/constants/app_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketRepository {
  IO.Socket? _socket;
  bool _isConnecting = false;
  String? _lastToken;
  String? _currentRoomId;

  // Message queue for offline messages
  final List<Map<String, dynamic>> _pendingMessages = [];
  bool _isSendingPending = false;

  // Connection state callbacks
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String error)? onError;

  // Connect to socket with enhanced error handling
  Future<void> connect(String token) async {
    if (_isConnecting) {
      print('⏳ Connection already in progress, waiting...');
      await _waitForConnection();
      return;
    }

    if (_socket != null && _socket!.connected) {
      print('✅ Socket already connected');
      return;
    }

    _isConnecting = true;
    _lastToken = token;

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔌 Creating socket connection...');
      print('   URL: ${AppConstants.socketUrl}');
      print('   Token: ${token.substring(0, 20)}...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Dispose old socket if exists
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }

      _socket = IO.io(
        AppConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports([
              'websocket',
              'polling',
            ]) // Try WebSocket first, fallback to polling
            .enableAutoConnect()
            .setAuth({'token': token})
            .setTimeout(30000) // 30 second timeout
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .enableForceNew() // Force new connection
            .build(),
      );

      _setupSocketListeners();

      _socket!.connect();

      await _waitForConnection();

      _isConnecting = false;

      // Send pending messages after reconnection
      if (_socket!.connected && _pendingMessages.isNotEmpty) {
        print('📤 Sending ${_pendingMessages.length} pending messages...');
        _sendPendingMessages();
      }
    } catch (e) {
      _isConnecting = false;
      print('❌ Socket connection failed: $e');
      throw Exception('Socket connection failed: $e');
    }
  }

  void _setupSocketListeners() {
_socket!.onConnect((_) {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ Socket connected successfully!');
  print('   Socket ID: ${_socket!.id}');
  print('   Transport: ${_socket!.io.engine?.transport?.name ?? "unknown"}');
  
  // ✅ ADD THIS: Re-join room after reconnect
  if (_currentRoomId != null) {
    print('🔄 Re-joining room after reconnect: $_currentRoomId');
    Future.delayed(Duration(milliseconds: 100), () {
      joinRoom(_currentRoomId!);
    });
  }
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  onConnected?.call();
});


    _socket!.onConnectError((data) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Socket connection error');
      print('   Error: $data');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onError?.call(data.toString());
    });

    _socket!.onDisconnect((reason) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔌 Socket disconnected');
      print('   Reason: $reason');
      print('   Will reconnect: ${_socket?.io.reconnectionAttempts != 0}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onDisconnected?.call();
    });

_socket!.onReconnect((attempt) {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔄 Socket reconnected!');
  print('   After attempts: $attempt');
  
  // ✅ ADD THIS: Re-join room after reconnect
  if (_currentRoomId != null) {
    print('🔄 Re-joining room: $_currentRoomId');
    Future.delayed(Duration(milliseconds: 100), () {
      joinRoom(_currentRoomId!);
    });
  }
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // Send pending messages after reconnection
  if (_pendingMessages.isNotEmpty) {
    print('📤 Sending ${_pendingMessages.length} pending messages...');
    _sendPendingMessages();
  }
});

    _socket!.onReconnectAttempt((attempt) {
      print('🔄 Reconnection attempt #$attempt...');
    });

    _socket!.onReconnectError((data) {
      print('❌ Reconnection error: $data');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ Reconnection failed after max attempts');
      onError?.call('Reconnection failed');
    });

    _socket!.onError((data) {
      print('❌ Socket error: $data');
      onError?.call(data.toString());
    });

    // Backend error events
    _socket!.on('error', (data) {
      print('❌ Backend error: $data');
    });
  }

  Future<void> _waitForConnection() async {
    int attempts = 0;
    const maxAttempts = 30; // 15 seconds total

    while (attempts < maxAttempts) {
      if (_socket?.connected == true) {
        print('✅ Socket connected successfully after ${attempts * 0.5}s');
        return;
      }

      await Future.delayed(Duration(milliseconds: 500));
      attempts++;

      if (attempts % 4 == 0) {
        print('   ⏳ Waiting for connection... ${attempts * 0.5}s');
      }
    }

    if (_socket?.connected != true) {
      print('⚠️ Socket connection timeout after ${maxAttempts * 0.5}s');
      throw Exception('Socket connection timeout');
    }
  }




// REPLACE the existing joinRoom method (around line 150) with this:
void joinRoom(String roomId) {
  if (_socket == null || !_socket!.connected) {
    print('⚠️ Cannot join room - socket not connected');
    return;
  }

  // ✅ Store current room
  _currentRoomId = roomId;

  _socket!.emit(AppConstants.joinRoomEvent, roomId);
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📍 Joined room: $roomId');
  print('   Socket ID: ${_socket!.id}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

  Future<void> sendMessage(
    String roomId,
    String text, {
    String? imageUrl,
    String? voiceUrl,
    int? voiceDuration,
  }) async {
    final messageData = {
      'roomId': roomId,
      'text': text,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 Attempting to send message');
    print('   Socket exists: ${_socket != null}');
    print('   Socket connected: ${_socket?.connected}');
    print('   Room: $roomId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // If not connected, queue the message and try to reconnect
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Socket not connected, queuing message...');
      _pendingMessages.add(messageData);
      print('📦 Message queued (${_pendingMessages.length} pending)');

      // Try to reconnect
      if (_lastToken != null) {
        print('🔄 Attempting reconnection...');
        try {
          await ensureConnected();
          // If reconnection successful, pending messages will be sent automatically
        } catch (e) {
          print('❌ Reconnection failed: $e');
          throw Exception('Socket not connected and reconnection failed');
        }
      } else {
        throw Exception('Socket not connected and no token available');
      }
      return;
    }

    // Socket is connected, send immediately
    _socket!.emit(AppConstants.sendMessageEvent, messageData);
    print('✅ Message emitted successfully');
  }

  Future<void> _sendPendingMessages() async {
    if (_isSendingPending || _pendingMessages.isEmpty) return;

    _isSendingPending = true;

    try {
      print('📤 Sending ${_pendingMessages.length} pending messages...');

      while (_pendingMessages.isNotEmpty && _socket?.connected == true) {
        final messageData = _pendingMessages.removeAt(0);

        _socket!.emit(AppConstants.sendMessageEvent, messageData);
        print('   ✅ Sent pending message');

        // Small delay between messages
        await Future.delayed(Duration(milliseconds: 100));
      }

      print('✅ All pending messages sent');
    } catch (e) {
      print('❌ Error sending pending messages: $e');
    } finally {
      _isSendingPending = false;
    }
  }

  void deleteMessage(String messageId, String roomId) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Cannot delete message - socket not connected');
      throw Exception('Socket not connected');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗑️ Deleting message: $messageId in room: $roomId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _socket!.emit(AppConstants.deleteMessageEvent, {
      'messageId': messageId,
      'roomId': roomId,
    });

    print('✅ Delete message emitted');
  }

  void sendTypingStatus(String roomId, bool isTyping) {
    if (_socket == null || !_socket!.connected) {
      // Silently fail for typing indicator
      return;
    }

    _socket!.emit(AppConstants.typingEvent, {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }


  void startCall(String roomId, String callType) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Cannot start call - socket not connected');
      throw Exception('Socket not connected');
    }

    print('📞 Starting $callType call in room: $roomId');
    _socket!.emit(AppConstants.startCallEvent, {
      'roomId': roomId,
      'callType': callType,
    });
  }

  void joinCall(String roomId, String callId) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Cannot join call - socket not connected');
      throw Exception('Socket not connected');
    }

    print('✅ Joining call: $callId in room: $roomId');
    _socket!.emit(AppConstants.joinCallEvent, {
      'roomId': roomId,
      'callId': callId,
    });
  }

  void rejectCall(String roomId, String callId) {
    if (_socket == null || !_socket!.connected) return;

    print('❌ Rejecting call: $callId');
    _socket!.emit(AppConstants.rejectCallEvent, {
      'roomId': roomId,
      'callId': callId,
    });
  }

  void leaveCall(String roomId, String callId) {
    if (_socket == null || !_socket!.connected) return;

    print('🚪 Leaving call: $callId');
    _socket!.emit(AppConstants.leaveCallEvent, {
      'roomId': roomId,
      'callId': callId,
    });
  }

  void toggleAudio(String roomId, bool isMuted) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit(AppConstants.toggleAudioEvent, {
      'roomId': roomId,
      'isMuted': isMuted,
    });
  }

  void toggleVideo(String roomId, bool isVideoOff) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit(AppConstants.toggleVideoEvent, {
      'roomId': roomId,
      'isVideoOff': isVideoOff,
    });
  }

  // ✅ CALL EVENT LISTENERS

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _socket?.on(AppConstants.incomingCallEvent, (data) {
      print('📞 INCOMING CALL EVENT');
      try {
        final callData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        callback(callData);
      } catch (e) {
        print('❌ Error in onIncomingCall: $e');
      }
    });
  }

  void onCallStarted(Function(Map<String, dynamic>) callback) {
    _socket?.on(AppConstants.callStartedEvent, (data) {
      print('📞 CALL STARTED EVENT');
      try {
        final callData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        callback(callData);
      } catch (e) {
        print('❌ Error in onCallStarted: $e');
      }
    });
  }

  void onUserJoinedCall(Function(Map<String, dynamic>) callback) {
    _socket?.on(AppConstants.userJoinedCallEvent, (data) {
      print('✅ USER JOINED CALL EVENT');
      try {
        final callData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        callback(callData);
      } catch (e) {
        print('❌ Error in onUserJoinedCall: $e');
      }
    });
  }

  void onUserLeftCall(Function(Map<String, dynamic>) callback) {
    _socket?.on(AppConstants.userLeftCallEvent, (data) {
      print('🚪 USER LEFT CALL EVENT');
      try {
        final callData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        callback(callData);
      } catch (e) {
        print('❌ Error in onUserLeftCall: $e');
      }
    });
  }

  void onCallEnded(Function(Map<String, dynamic>) callback) {
    _socket?.on(AppConstants.callEndedEvent, (data) {
      print('🏁 CALL ENDED EVENT');
      try {
        final callData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        callback(callData);
      } catch (e) {
        print('❌ Error in onCallEnded: $e');
      }
    });
  }

  void onCallError(Function(Map<String, dynamic>) callback) {
    _socket?.on(AppConstants.callErrorEvent, (data) {
      print('❌ CALL ERROR EVENT');
      try {
        final callData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        callback(callData);
      } catch (e) {
        print('❌ Error in onCallError: $e');
      }
    });
  }

void onReceiveMessage(Function(Map<String, dynamic>) callback) {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('👂 Setting up receiveMessage listener');
  print('   Event: ${AppConstants.receiveMessageEvent}');
  print('   Socket ID: ${_socket?.id}');
  print('   Connected: ${_socket?.connected}');
  
  // ✅ CRITICAL FIX: Remove old listener first!
  _socket?.off(AppConstants.receiveMessageEvent);
  print('   🧹 Cleared old listeners');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  _socket?.on(AppConstants.receiveMessageEvent, (data) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📩 SOCKET RECEIVED MESSAGE');
    print('   Type: ${data.runtimeType}');
    print('   Socket ID: ${_socket?.id}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      Map<String, dynamic> messageData;

      if (data is Map<String, dynamic>) {
        messageData = data;
      } else if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else {
        print('❌ Unexpected data type: ${data.runtimeType}');
        return;
      }

      callback(messageData);
    } catch (e, stackTrace) {
      print('❌ Error in onReceiveMessage: $e');
      print('Stack trace: $stackTrace');
    }
  });
  
  print('✅ receiveMessage listener registered');
}


  void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    print('👂 Setting up messageDeleted listener');

    _socket?.on(AppConstants.messageDeletedEvent, (data) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🗑️ MESSAGE DELETED EVENT');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      try {
        Map<String, dynamic> deleteData;

        if (data is Map<String, dynamic>) {
          deleteData = data;
        } else if (data is Map) {
          deleteData = Map<String, dynamic>.from(data);
        } else {
          print('❌ Unexpected data type: ${data.runtimeType}');
          return;
        }

        callback(deleteData);
      } catch (e, stackTrace) {
        print('❌ Error in onMessageDeleted: $e');
        print('Stack trace: $stackTrace');
      }
    });
  }

  void onTypingUpdate(Function(List<Map<String, dynamic>>) callback) {
    print('👂 Setting up typingUpdate listener');

    _socket?.on(AppConstants.typingUpdateEvent, (data) {
      try {
        if (data is Map<String, dynamic> && data.containsKey('typingUsers')) {
          final typingUsers = data['typingUsers'] as List;
          final users = typingUsers
              .map((user) => Map<String, dynamic>.from(user as Map))
              .toList();

          callback(users);
        }
      } catch (e, stackTrace) {
        print('❌ Error in onTypingUpdate: $e');
        print('Stack trace: $stackTrace');
      }
    });
  }

  void onOnlineUsers(Function(List<String>) callback) {
    _socket?.on(AppConstants.onlineUsersEvent, (data) {
      print('👥 Online users event received: $data');
      final users = (data as List).map((e) => e.toString()).toList();
      callback(users);
    });
  }

  bool get isConnected => _socket?.connected ?? false;

  int get pendingMessageCount => _pendingMessages.length;

  Future<void> ensureConnected() async {
    if (_socket == null || _lastToken == null) {
      print('❌ Socket is null or no token - cannot reconnect');
      throw Exception('Socket not initialized. Call connect() first.');
    }

    if (_socket!.connected) {
      print('✅ Socket is already connected');
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 Socket not connected, reconnecting...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Try to reconnect with last token
    try {
      await connect(_lastToken!);
      print('✅ Reconnection successful');
    } catch (e) {
      print('❌ Reconnection failed: $e');
      throw Exception('Socket reconnection failed: $e');
    }
  }

void disconnect() {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔌 Disconnecting socket...');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  _currentRoomId = null; // ✅ ADD THIS LINE
  _socket?.disconnect();
  _socket?.dispose();
  _socket = null;
  _isConnecting = false;

  print('✅ Socket disconnected and disposed');
}
  void clearPendingMessages() {
    print('🧹 Clearing ${_pendingMessages.length} pending messages');
    _pendingMessages.clear();
  }
}
