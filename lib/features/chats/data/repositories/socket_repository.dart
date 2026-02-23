// features/chats/data/repositories/socket_repository.dart
// ✅ FIXED: Stream-based architecture - Single listener, multiple subscribers

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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ STREAMS: Single source of truth for all events
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageUpdatedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _onlineUsersStreamController = StreamController<List<String>>.broadcast();
  
  // Call event streams
  final _incomingCallStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callStartedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _userJoinedCallStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _userLeftCallStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callErrorStreamController = StreamController<Map<String, dynamic>>.broadcast();

  // ✅ EXPOSE STREAMS (not callbacks)
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get messageDeletedStream => _messageDeletedStreamController.stream;
  Stream<Map<String, dynamic>> get messageUpdatedStream => _messageUpdatedStreamController.stream;
  Stream<List<Map<String, dynamic>>> get typingStream => _typingStreamController.stream;
  Stream<List<String>> get onlineUsersStream => _onlineUsersStreamController.stream;
  
  // Call streams
  Stream<Map<String, dynamic>> get incomingCallStream => _incomingCallStreamController.stream;
  Stream<Map<String, dynamic>> get callStartedStream => _callStartedStreamController.stream;
  Stream<Map<String, dynamic>> get userJoinedCallStream => _userJoinedCallStreamController.stream;
  Stream<Map<String, dynamic>> get userLeftCallStream => _userLeftCallStreamController.stream;
  Stream<Map<String, dynamic>> get callEndedStream => _callEndedStreamController.stream;
  Stream<Map<String, dynamic>> get callErrorStream => _callErrorStreamController.stream;

  // Connection state callbacks (keep these for simple notifications)
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String error)? onError;

  // ✅ CRITICAL: Track if listeners are registered (ONCE per socket lifecycle)
  bool _listenersRegistered = false;

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
        _listenersRegistered = false; // ✅ Reset listener flag
      }

      _socket = IO.io(
        AppConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .setTimeout(30000)
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .enableForceNew()
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

      // ✅ Re-join room after reconnect
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

      // ✅ Re-join room after reconnect
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

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ✅ REGISTER EVENT LISTENERS ONCE
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _registerEventListeners();
  }

  void _registerEventListeners() {
    if (_listenersRegistered) {
      print('⚠️ Event listeners already registered, skipping');
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 Registering socket event listeners (ONCE)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // ✅ MESSAGE EVENTS
    _socket!.on(AppConstants.receiveMessageEvent, (data) {
      print('📨 Socket event: receiveMessage');
      try {
        final messageData = _normalizeData(data);
        _messageStreamController.add(messageData);
        print('✅ Message added to stream');
      } catch (e) {
        print('❌ Error in message listener: $e');
      }
    });

    _socket!.on(AppConstants.messageDeletedEvent, (data) {
      print('🗑️ Socket event: messageDeleted');
      try {
        final deleteData = _normalizeData(data);
        _messageDeletedStreamController.add(deleteData);
        print('✅ Delete event added to stream');
      } catch (e) {
        print('❌ Error in delete listener: $e');
      }
    });

    _socket!.on('messageUpdated', (data) {
      print('🔄 Socket event: messageUpdated');
      try {
        final updateData = _normalizeData(data);
        _messageUpdatedStreamController.add(updateData);
        print('✅ Update event added to stream');
      } catch (e) {
        print('❌ Error in update listener: $e');
      }
    });

    // ✅ TYPING & ONLINE USERS
    _socket!.on(AppConstants.typingUpdateEvent, (data) {
      try {
        if (data is Map<String, dynamic> && data.containsKey('typingUsers')) {
          final typingUsers = (data['typingUsers'] as List)
              .map((user) => Map<String, dynamic>.from(user as Map))
              .toList();
          _typingStreamController.add(typingUsers);
        }
      } catch (e) {
        print('❌ Error in typing listener: $e');
      }
    });

    _socket!.on(AppConstants.onlineUsersEvent, (data) {
      try {
        final users = (data as List).map((e) => e.toString()).toList();
        _onlineUsersStreamController.add(users);
      } catch (e) {
        print('❌ Error in online users listener: $e');
      }
    });

    // ✅ CALL EVENTS
    _socket!.on(AppConstants.incomingCallEvent, (data) {
      print('📞 Socket event: incoming_call');
      try {
        final callData = _normalizeData(data);
        _incomingCallStreamController.add(callData);
        print('✅ Incoming call added to stream');
      } catch (e) {
        print('❌ Error in incoming call listener: $e');
      }
    });

    _socket!.on(AppConstants.callStartedEvent, (data) {
      print('📞 Socket event: call_started');
      try {
        final callData = _normalizeData(data);
        _callStartedStreamController.add(callData);
      } catch (e) {
        print('❌ Error in call started listener: $e');
      }
    });

    _socket!.on(AppConstants.userJoinedCallEvent, (data) {
      print('✅ Socket event: user_joined_call');
      try {
        final callData = _normalizeData(data);
        _userJoinedCallStreamController.add(callData);
      } catch (e) {
        print('❌ Error in user joined listener: $e');
      }
    });

    _socket!.on(AppConstants.userLeftCallEvent, (data) {
      print('🚪 Socket event: user_left_call');
      try {
        final callData = _normalizeData(data);
        _userLeftCallStreamController.add(callData);
      } catch (e) {
        print('❌ Error in user left listener: $e');
      }
    });

    _socket!.on(AppConstants.callEndedEvent, (data) {
      print('🏁 Socket event: call_ended');
      try {
        final callData = _normalizeData(data);
        _callEndedStreamController.add(callData);
      } catch (e) {
        print('❌ Error in call ended listener: $e');
      }
    });

    _socket!.on(AppConstants.callErrorEvent, (data) {
      print('❌ Socket event: call_error');
      try {
        final errorData = _normalizeData(data);
        _callErrorStreamController.add(errorData);
      } catch (e) {
        print('❌ Error in call error listener: $e');
      }
    });

    _listenersRegistered = true;
    print('✅ All event listeners registered successfully');
    print('   These listeners will persist for socket lifetime');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // ✅ Helper to normalize socket data to Map<String, dynamic>
  Map<String, dynamic> _normalizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception('Unexpected data type: ${data.runtimeType}');
    }
  }

  Future<void> _waitForConnection() async {
    int attempts = 0;
    const maxAttempts = 30;

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

  void joinRoom(String roomId) {
    final joinTime = DateTime.now();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 JOIN ROOM REQUEST');
    print('   Room ID: $roomId');
    print('   Time: ${joinTime.toIso8601String()}');
    print('   Socket Connected: ${_socket?.connected}');
    print('   Previous Room: $_currentRoomId');

    if (_socket == null || !_socket!.connected) {
      print('❌ Cannot join room - socket not connected');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    // Force leave/rejoin to reset Socket.IO state
    if (_currentRoomId == roomId) {
      print('🔄 Same room - forcing rejoin to reset state');
      _socket!.emit('leaveRoom', roomId);
      Future.delayed(Duration(milliseconds: 50), () {
        _socket!.emit(AppConstants.joinRoomEvent, roomId);
        print('✅ Forced rejoin completed');
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    _currentRoomId = roomId;
    _socket!.emit(AppConstants.joinRoomEvent, roomId);

    print('✅ joinRoom event emitted');
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

    print('📤 Sending message to room: $roomId');

    if (_socket == null || !_socket!.connected) {
      print('⚠️ Socket not connected, queuing message...');
      _pendingMessages.add(messageData);
      
      if (_lastToken != null) {
        try {
          await ensureConnected();
        } catch (e) {
          print('❌ Reconnection failed: $e');
          throw Exception('Socket not connected');
        }
      }
      return;
    }

    _socket!.emit(AppConstants.sendMessageEvent, messageData);
    print('✅ Message emitted');
  }

  Future<void> _sendPendingMessages() async {
    if (_isSendingPending || _pendingMessages.isEmpty) return;

    _isSendingPending = true;

    try {
      while (_pendingMessages.isNotEmpty && _socket?.connected == true) {
        final messageData = _pendingMessages.removeAt(0);
        _socket!.emit(AppConstants.sendMessageEvent, messageData);
        await Future.delayed(Duration(milliseconds: 100));
      }
      print('✅ All pending messages sent');
    } finally {
      _isSendingPending = false;
    }
  }

  void deleteMessage(String messageId, String roomId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    _socket!.emit(AppConstants.deleteMessageEvent, {
      'messageId': messageId,
      'roomId': roomId,
    });
  }

  void sendTypingStatus(String roomId, bool isTyping) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit(AppConstants.typingEvent, {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CALL METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void startCall(String roomId, String callType) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    _socket!.emit(AppConstants.startCallEvent, {
      'roomId': roomId,
      'callType': callType,
    });
  }

  void joinCall(String roomId, String callId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    _socket!.emit(AppConstants.joinCallEvent, {
      'roomId': roomId,
      'callId': callId,
    });
  }

  void rejectCall(String roomId, String callId) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit(AppConstants.rejectCallEvent, {
      'roomId': roomId,
      'callId': callId,
    });
  }

  void leaveCall(String roomId, String callId) {
    if (_socket == null || !_socket!.connected) return;

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

  bool get isConnected => _socket?.connected ?? false;

  int get pendingMessageCount => _pendingMessages.length;

  Future<void> ensureConnected() async {
    if (_socket == null || _lastToken == null) {
      throw Exception('Socket not initialized. Call connect() first.');
    }

    if (_socket!.connected) {
      return;
    }

    await connect(_lastToken!);
  }

  void disconnect() {
    print('🔌 Disconnecting socket...');

    _currentRoomId = null;
    _listenersRegistered = false;

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;

    print('✅ Socket disconnected');
  }

  void clearPendingMessages() {
    _pendingMessages.clear();
  }

  // ✅ Dispose streams when repository is disposed
  void dispose() {
    _messageStreamController.close();
    _messageDeletedStreamController.close();
    _messageUpdatedStreamController.close();
    _typingStreamController.close();
    _onlineUsersStreamController.close();
    _incomingCallStreamController.close();
    _callStartedStreamController.close();
    _userJoinedCallStreamController.close();
    _userLeftCallStreamController.close();
    _callEndedStreamController.close();
    _callErrorStreamController.close();
    disconnect();
  }
}