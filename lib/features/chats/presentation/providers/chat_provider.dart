// features/chats/presentation/providers/chat_provider.dart

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

  ChatController(this.roomId, this._ref) : super(ChatState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoading: true);

    try {
      print('🚀 Initializing chat for room: $roomId');

      final socketController = _ref.read(socketControllerProvider.notifier);
      await socketController.connect();

      // ✅ CRITICAL: Register listener FIRST, before joining room
      print('👂 Setting up message listener BEFORE joining room...');
      socketController.onReceiveMessage((data) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📩 ChatController received message');
        print('   Raw data: $data');
        print('   Controller disposed: $_isDisposed');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        if (_isDisposed) {
          print('⏭️ Controller disposed, skipping');
          return;
        }

        try {
          final messageRoomId = _extractRoomId(data['roomId']);

          print('🔍 Room ID comparison:');
          print('   Extracted message roomId: $messageRoomId');
          print('   Current roomId: $roomId');
          print('   Match: ${messageRoomId == roomId}');

          if (messageRoomId != null && messageRoomId != roomId) {
            print('⏭️ Message for different room, skipping');
            return;
          }

          print('✅ Message is for this room, parsing...');
          final newMessage = Message.fromJson(data);
          print(
            '✅ Message parsed: id=${newMessage.id}, text="${newMessage.text}"',
          );

          final uploadingIndex = state.messages.indexWhere(
            (m) =>
                m.isUploading &&
                ((m.imageUrl == newMessage.imageUrl && m.imageUrl != null) ||
                    (m.voiceUrl == newMessage.voiceUrl && m.voiceUrl != null)),
          );

          if (uploadingIndex != -1) {
            print('✅ Replacing uploading message at index $uploadingIndex');
            final updatedMessages = [...state.messages];
            updatedMessages[uploadingIndex] = newMessage;
            state = state.copyWith(messages: updatedMessages);
            print('✅ Message replaced! Total: ${state.messages.length}');
            return;
          }

          final messageExists = state.messages.any(
            (m) => m.id == newMessage.id,
          );

          if (messageExists) {
            print('⏭️ Message already exists (id: ${newMessage.id}), skipping');
            return;
          }

          print(
            '✅ Adding new message to UI (current: ${state.messages.length})',
          );

          state = state.copyWith(messages: [...state.messages, newMessage]);

          print('✅ Message added! New count: ${state.messages.length}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        } catch (e, stackTrace) {
          print('❌ Error processing message: $e');
          print('Stack trace: $stackTrace');
        }
      });

      print('✅ Listener registered');

      // ✅ NOW join the room (after listener is registered)
      print('📍 Joining room...');
      socketController.joinRoom(roomId);

      // ✅ Wait to ensure backend processed the join
      await Future.delayed(Duration(milliseconds: 300));

      print('📜 Loading message history...');
      final chatRepository = _ref.read(chatRepositoryProvider);
      final messagesData = await chatRepository.getRoomMessages(roomId);
      final messages = messagesData.map((m) => Message.fromJson(m)).toList();

      if (_isDisposed) return;
      state = state.copyWith(messages: messages, isLoading: false);

      print('✅ Loaded ${messages.length} messages');

      // ✅ Setup message deleted listener
      print('👂 Setting up message deleted listener...');
      socketController.onMessageDeleted((data) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🗑️ Message deleted event received');
        print('   Data: $data');
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
          print('✅ Message marked as deleted in UI');
        } catch (e, stackTrace) {
          print('❌ Error processing message deleted: $e');
          print('Stack trace: $stackTrace');
        }
      });

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

  void sendMessage(
    String text, {
    String? imageUrl,
    String? voiceUrl,
    int? voiceDuration,
  }) {
    if (_isDisposed ||
        (text.trim().isEmpty && imageUrl == null && voiceUrl == null))
      return;

    // ✅ Stop typing when sending message
    _stopTyping();

    final socketController = _ref.read(socketControllerProvider.notifier);
    socketController.sendMessage(
      roomId,
      text,
      imageUrl: imageUrl,
      voiceUrl: voiceUrl,
      voiceDuration: voiceDuration,
    );
  }

  // ✅ NEW: Delete message
  Future<void> deleteMessage(String messageId) async {
    if (_isDisposed) return;

    try {
      print('🗑️ Requesting message deletion: $messageId');

      final socketController = _ref.read(socketControllerProvider.notifier);
      socketController.deleteMessage(messageId, roomId);

      print('✅ Delete request sent');
    } catch (e) {
      print('❌ Error deleting message: $e');
      if (_isDisposed) return;
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ✅ NEW: Send typing status
  void sendTypingStatus(bool isTyping) {
    if (_isDisposed) return;

    final socketController = _ref.read(socketControllerProvider.notifier);
    socketController.sendTypingStatus(roomId, isTyping);

    // Auto-stop typing after 2 seconds
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

  void refreshSocketListener() {
  if (_isDisposed) return;
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔄 Refreshing socket listener for room: $roomId');
  print('   Messages in state: ${state.messages.length}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final socketController = _ref.read(socketControllerProvider.notifier);
  
  // Re-join the room to ensure we're in it
  socketController.joinRoom(roomId);
  
  // Re-register the message listener
  socketController.onReceiveMessage((data) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📩 ChatController received message (REFRESHED LISTENER)');
    print('   Raw data: $data');
    print('   Controller disposed: $_isDisposed');
    print('   Current messages: ${state.messages.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (_isDisposed) {
      print('⏭️ Controller disposed, skipping');
      return;
    }

    try {
      final messageRoomId = _extractRoomId(data['roomId']);

      print('🔍 Room ID comparison:');
      print('   Message room: $messageRoomId');
      print('   This controller: $roomId');
      print('   Match: ${messageRoomId == roomId}');

      if (messageRoomId != null && messageRoomId != roomId) {
        print('⏭️ Message for different room, skipping');
        return;
      }

      print('✅ Message is for this room, parsing...');
      final newMessage = Message.fromJson(data);
      print('✅ Message parsed: id=${newMessage.id}, text="${newMessage.text}"');

      // Check for uploading message to replace
      final uploadingIndex = state.messages.indexWhere(
        (m) =>
            m.isUploading &&
            ((m.imageUrl == newMessage.imageUrl && m.imageUrl != null) ||
                (m.voiceUrl == newMessage.voiceUrl && m.voiceUrl != null)),
      );

      if (uploadingIndex != -1) {
        print('✅ Replacing uploading message at index $uploadingIndex');
        final updatedMessages = [...state.messages];
        updatedMessages[uploadingIndex] = newMessage;
        state = state.copyWith(messages: updatedMessages);
        print('✅ Message replaced! Total: ${state.messages.length}');
        return;
      }

      // Check if message already exists
      final messageExists = state.messages.any((m) => m.id == newMessage.id);

      if (messageExists) {
        print('⏭️ Message already exists (id: ${newMessage.id}), skipping');
        return;
      }

      print('✅ Adding new message to UI (current: ${state.messages.length})');
      state = state.copyWith(messages: [...state.messages, newMessage]);
      print('✅ Message added! New count: ${state.messages.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      print('❌ Error processing message: $e');
      print('Stack trace: $stackTrace');
    }
  });
  
  print('✅ Socket listener refreshed for room: $roomId');
}


  Future<void> uploadAndSendVoice(
    File voiceFile,
    int duration,
    String text,
  ) async {
    if (_isDisposed) return;

    try {
      print('1️⃣ Starting voice upload...');

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

      print('2️⃣ Voice uploaded successfully: ${result['voiceUrl']}');

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
      print('3️⃣ Ensuring socket connection...');
      await socketController.ensureConnected();

      print('4️⃣ Sending voice message via socket...');
      sendMessage(text, voiceUrl: result['voiceUrl'], voiceDuration: duration);

      print('✅ Voice message sent successfully');
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
    _isDisposed = true;
    _typingTimer?.cancel();
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
