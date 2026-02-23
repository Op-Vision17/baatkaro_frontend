// features/chats/presentation/providers/chat_provider.dart
// ✅ FIXED: Stream subscriptions instead of callback registration

import 'dart:async';
import 'dart:io';
import 'package:baatkaro/features/chats/data/models/message_model.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_provider.dart';
import '../../../home/presentation/providers/room_provider.dart';

// Chat State for a specific room
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isUploading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

String? _extractRoomId(dynamic roomIdData) {
  if (roomIdData == null) return null;

  if (roomIdData is String) {
    return roomIdData;
  }

  if (roomIdData is Map) {
    if (roomIdData.containsKey('\$oid')) {
      return roomIdData['\$oid'].toString();
    }
    if (roomIdData.containsKey('_id')) {
      return roomIdData['_id'].toString();
    }
    if (roomIdData.containsKey('id')) {
      return roomIdData['id'].toString();
    }
  }

  return roomIdData.toString();
}

// Chat Controller for a specific room
class ChatController extends StateNotifier<ChatState> {
  final String roomId;
  final Ref _ref;
  bool _isDisposed = false;
  Timer? _typingTimer;
  
  // ✅ Stream subscriptions (disposed when controller is disposed)
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageDeletedSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageUpdatedSubscription;
  
  final String _instanceId = DateTime.now().millisecondsSinceEpoch.toString();
  static int _instanceCounter = 0;
  final int _instanceNumber;

  ChatController(this.roomId, this._ref) : 
    _instanceNumber = ++_instanceCounter,
    super(ChatState()) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏗️ ChatController CREATED');
    print('   Room: $roomId');
    print('   Instance ID: $_instanceId');
    print('   Instance Number: $_instanceNumber');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoading: true);

    try {
      print('🚀 Initializing chat for room: $roomId');

      final socketController = _ref.read(socketControllerProvider.notifier);
      await socketController.connect();

      // ✅ SUBSCRIBE TO STREAMS (not register callbacks)
      _setupStreamSubscriptions();

      // Join room
      print('📍 Joining room...');
      socketController.joinRoom(roomId);

      await Future.delayed(Duration(milliseconds: 300));

      // Load message history
      print('📜 Loading message history...');
      final chatRepository = _ref.read(chatRepositoryProvider);
      final messagesData = await chatRepository.getRoomMessages(roomId);
      final messages = messagesData.map((m) => Message.fromJson(m)).toList();

      if (_isDisposed) return;
      state = state.copyWith(messages: messages, isLoading: false);

      print('✅ Loaded ${messages.length} messages');
      print('✅ Chat initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing chat: $e');
      print('Stack trace: $stackTrace');
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ✅ NEW: Setup stream subscriptions
  void _setupStreamSubscriptions() {
    final socketRepository = _ref.read(socketRepositoryProvider);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📡 Setting up stream subscriptions');
    print('   Instance: $_instanceNumber');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // ✅ Subscribe to message stream
    _messageSubscription = socketRepository.messageStream.listen(
      (data) => _handleIncomingMessage(data),
      onError: (error) {
        print('❌ Message stream error: $error');
      },
    );

    // ✅ Subscribe to message deleted stream
    _messageDeletedSubscription = socketRepository.messageDeletedStream.listen(
      (data) => _handleMessageDeleted(data),
      onError: (error) {
        print('❌ Delete stream error: $error');
      },
    );

    // ✅ Subscribe to message updated stream
    _messageUpdatedSubscription = socketRepository.messageUpdatedStream.listen(
      (data) => _handleMessageUpdated(data),
      onError: (error) {
        print('❌ Update stream error: $error');
      },
    );

    print('✅ Stream subscriptions setup complete');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // ✅ Handle incoming message from stream
  void _handleIncomingMessage(Map<String, dynamic> data) {
    final receiveTime = DateTime.now();
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📩 MESSAGE RECEIVED (Stream)');
    print('   Instance: $_instanceNumber');
    print('   Time: ${receiveTime.toIso8601String()}');
    print('   Disposed: $_isDisposed');
    print('   Messages in State: ${state.messages.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (_isDisposed) {
      print('❌ MESSAGE DROPPED - Controller Disposed!');
      return;
    }

    try {
      final messageRoomId = _extractRoomId(data['roomId']);

      print('🔍 Room Validation:');
      print('   Message Room: $messageRoomId');
      print('   This Controller Room: $roomId');
      print('   Match: ${messageRoomId == roomId}');

      if (messageRoomId != null && messageRoomId != roomId) {
        print('⏭️ MESSAGE SKIPPED - Wrong Room');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      final newMessage = Message.fromJson(data);
      
      print('📝 Message Parsed:');
      print('   ID: ${newMessage.id}');
      print('   Text: "${newMessage.text}"');
      print('   Sender: ${newMessage.sender.name}');

      // Check for uploading message to replace
      final uploadingIndex = state.messages.indexWhere(
        (m) =>
            m.isUploading &&
            ((m.imageUrl == newMessage.imageUrl && m.imageUrl != null) ||
                (m.voiceUrl == newMessage.voiceUrl && m.voiceUrl != null)),
      );

      if (uploadingIndex != -1) {
        print('🔄 Replacing uploading message at index $uploadingIndex');
        final updatedMessages = [...state.messages];
        updatedMessages[uploadingIndex] = newMessage;
        state = state.copyWith(messages: updatedMessages);
        print('✅ Upload complete!');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // Check if message already exists
      final messageExists = state.messages.any((m) => m.id == newMessage.id);

      if (messageExists) {
        print('⏭️ MESSAGE DUPLICATE - Already Exists');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      print('➕ Adding NEW message to state');
      state = state.copyWith(messages: [...state.messages, newMessage]);
      
      print('✅ MESSAGE ADDED SUCCESSFULLY!');
      print('   New count: ${state.messages.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
    } catch (e, stackTrace) {
      print('❌ ERROR PROCESSING MESSAGE: $e');
      print('   Stack: $stackTrace');
    }
  }

  // ✅ Handle message deleted from stream
  void _handleMessageDeleted(Map<String, dynamic> data) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗑️ Message deleted event (Stream)');
    print('   Instance: $_instanceNumber');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (_isDisposed) return;

    try {
      final messageId = data['messageId']?.toString();
      final deletedAt = data['deletedAt'] != null
          ? DateTime.parse(data['deletedAt'].toString())
          : DateTime.now();

      if (messageId == null) {
        print('❌ No messageId in delete event');
        return;
      }

      print('🗑️ Marking message as deleted: $messageId');

      final updatedMessages = state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(
            isDeleted: true,
            deletedAt: deletedAt,
            deletedBy: data['deletedBy']?.toString(),
          );
        }
        return m;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
      print('✅ Message marked as deleted');
    } catch (e) {
      print('❌ Error processing delete: $e');
    }
  }

  // ✅ Handle message updated from stream
  void _handleMessageUpdated(Map<String, dynamic> data) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 MESSAGE UPDATED (Stream)');
    print('   Instance: $_instanceNumber');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (_isDisposed) return;

    try {
      final updatedMessage = Message.fromJson(data);
      
      print('📝 Message Updated Details:');
      print('   Message ID: ${updatedMessage.id}');
      print('   Message Type: ${updatedMessage.messageType}');
      
      if (updatedMessage.isCallMessage && updatedMessage.callData != null) {
        print('   Call Status: ${updatedMessage.callData!.status}');
      }

      final messageIndex = state.messages.indexWhere(
        (msg) => msg.id == updatedMessage.id,
      );

      if (messageIndex != -1) {
        print('   ✅ Found message at index: $messageIndex');
        
        final updatedMessages = List<Message>.from(state.messages);
        updatedMessages[messageIndex] = updatedMessage;

        state = state.copyWith(messages: updatedMessages);
        print('   ✅ Message updated successfully!');
      } else {
        print('   ⚠️ Message not found, adding to state');
        final updatedMessages = [...state.messages, updatedMessage];
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: updatedMessages);
      }
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      print('❌ ERROR PROCESSING UPDATE: $e');
      print('   Stack: $stackTrace');
    }
  }

  void sendMessage(
    String text, {
    String? imageUrl,
    String? voiceUrl,
    int? voiceDuration,
  }) {
    if (_isDisposed ||
        (text.trim().isEmpty && imageUrl == null && voiceUrl == null))
      return;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 SENDING MESSAGE');
    print('   Instance: $_instanceNumber');
    print('   Room: $roomId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _stopTyping();

    try {
      final socketController = _ref.read(socketControllerProvider.notifier);
      socketController.sendMessage(
        roomId,
        text,
        imageUrl: imageUrl,
        voiceUrl: voiceUrl,
        voiceDuration: voiceDuration,
      );
      
      print('✅ Message sent to socket');
    } catch (e) {
      print('❌ ERROR SENDING MESSAGE: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_isDisposed) return;

    try {
      final socketController = _ref.read(socketControllerProvider.notifier);
      socketController.deleteMessage(messageId, roomId);
    } catch (e) {
      print('❌ Error deleting message: $e');
    }
  }

  void sendTypingStatus(bool isTyping) {
    if (_isDisposed) return;

    final socketController = _ref.read(socketControllerProvider.notifier);
    socketController.sendTypingStatus(roomId, isTyping);

    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(Duration(seconds: 2), () {
        _stopTyping();
      });
    }
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;

    if (_isDisposed) return;

    final socketController = _ref.read(socketControllerProvider.notifier);
    socketController.sendTypingStatus(roomId, false);
  }

  Future<void> uploadAndSendImage(File imageFile, String text) async {
    if (_isDisposed) return;

    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('userName') ?? 'You';
      final userEmail = prefs.getString('userEmail') ?? '';

      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        localFilePath: imageFile.path,
        sender: MessageSender(id: userId, name: userName, email: userEmail),
        createdAt: DateTime.now(),
        isUploading: true,
        uploadProgress: 0.0,
      );

      state = state.copyWith(
        messages: [...state.messages, tempMessage],
        isUploading: true,
      );

      final chatRepository = _ref.read(chatRepositoryProvider);
      final imageUrl = await chatRepository.uploadImage(imageFile);

      if (_isDisposed) return;

      final updatedMessages = state.messages.map((m) {
        if (m.id == tempMessage.id) {
          return m.copyWith(imageUrl: imageUrl, uploadProgress: 1.0);
        }
        return m;
      }).toList();

      state = state.copyWith(messages: updatedMessages);

      sendMessage(text, imageUrl: imageUrl);

      state = state.copyWith(isUploading: false);
    } catch (e) {
      print('❌ Error uploading image: $e');
      if (_isDisposed) return;
      state = state.copyWith(
        isUploading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> uploadAndSendVoice(
    File voiceFile,
    int duration,
    String text,
  ) async {
    if (_isDisposed) return;

    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('userName') ?? 'You';
      final userEmail = prefs.getString('userEmail') ?? '';

      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        voiceUrl: null,
        voiceDuration: duration,
        sender: MessageSender(id: userId, name: userName, email: userEmail),
        createdAt: DateTime.now(),
        isUploading: true,
        uploadProgress: 0.0,
      );

      state = state.copyWith(
        messages: [...state.messages, tempMessage],
        isUploading: true,
      );

      final chatRepository = _ref.read(chatRepositoryProvider);
      final result = await chatRepository.uploadVoice(voiceFile);

      if (_isDisposed) return;

      final updatedMessages = state.messages.map((m) {
        if (m.id == tempMessage.id) {
          return m.copyWith(voiceUrl: result['voiceUrl'], uploadProgress: 1.0);
        }
        return m;
      }).toList();

      state = state.copyWith(messages: updatedMessages);

      await Future.delayed(Duration(milliseconds: 500));

      final socketController = _ref.read(socketControllerProvider.notifier);
      await socketController.ensureConnected();

      sendMessage(text, voiceUrl: result['voiceUrl'], voiceDuration: duration);

      state = state.copyWith(isUploading: false);
    } catch (e) {
      print('❌ Error in uploadAndSendVoice: $e');
      if (_isDisposed) return;
      state = state.copyWith(
        isUploading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  void dispose() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💀 ChatController DISPOSING');
    print('   Room: $roomId');
    print('   Instance: $_instanceNumber');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    _isDisposed = true;
    _typingTimer?.cancel();
    
    // ✅ Cancel stream subscriptions
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageUpdatedSubscription?.cancel();
    
    print('✅ Stream subscriptions cancelled');
    
    super.dispose();
  }
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, ChatState, String>((
      ref,
      roomId,
    ) {
      return ChatController(roomId, ref);
    });