// chat_screen.dart - FIXED: Relies only on socket events, no HTTP polling

import 'dart:io';
import 'dart:async';
import 'package:baatkaro/features/calls/presentation/provider/call_provider.dart';
import 'package:baatkaro/features/calls/presentation/screens/call_screen.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/chat_input_field.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/date_separator.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/empty_chat_state.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/image_options_bottomsheet.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/message_bubble.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/voice_recorder.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/room_code_dialog.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/typing_indicator.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:baatkaro/shared/services/permission_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';
import '../../../home/presentation/providers/room_provider.dart';
import '../providers/socket_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  final String? roomCode;

  ChatScreen({required this.roomId, required this.roomName, this.roomCode});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRecordingVoice = false;
  Timer? _typingDebounceTimer;
  bool _isCurrentlyTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);

    // ✅ NO MORE _checkForActiveCall() - Socket handles this via chatSocket.js joinRoom event
    print('🎯 ChatScreen initialized for room: ${widget.roomId}');
    print('   Active calls will be shown via socket events only');
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingDebounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText && !_isCurrentlyTyping) {
      setState(() => _isCurrentlyTyping = true);
      ref
          .read(chatControllerProvider(widget.roomId).notifier)
          .sendTypingStatus(true);
    }
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(Duration(seconds: 2), () {
      if (_isCurrentlyTyping) {
        setState(() => _isCurrentlyTyping = false);
        ref
            .read(chatControllerProvider(widget.roomId).notifier)
            .sendTypingStatus(false);
      }
    });
    if (!hasText && _isCurrentlyTyping) {
      setState(() => _isCurrentlyTyping = false);
      ref
          .read(chatControllerProvider(widget.roomId).notifier)
          .sendTypingStatus(false);
      _typingDebounceTimer?.cancel();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    if (_isCurrentlyTyping) {
      setState(() => _isCurrentlyTyping = false);
      _typingDebounceTimer?.cancel();
    }
    ref
        .read(chatControllerProvider(widget.roomId).notifier)
        .sendMessage(_messageController.text);
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      final text = _messageController.text.trim();
      await ref
          .read(chatControllerProvider(widget.roomId).notifier)
          .uploadAndSendImage(File(pickedFile.path), text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Failed to send image: $e');
    }
  }

  Future<void> _takePhotoAndSend() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      final text = _messageController.text.trim();
      await ref
          .read(chatControllerProvider(widget.roomId).notifier)
          .uploadAndSendImage(File(pickedFile.path), text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Failed to send photo: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageOptionsBottomSheet(
        onGallery: () {
          Navigator.pop(context);
          _pickAndSendImage();
        },
        onCamera: () {
          Navigator.pop(context);
          _takePhotoAndSend();
        },
      ),
    );
  }

  void _viewFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) =>
                      CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startVoiceRecording() {
    setState(() => _isRecordingVoice = true);
  }

  void _cancelVoiceRecording() {
    setState(() => _isRecordingVoice = false);
  }

  Future<void> _sendVoiceMessage(File voiceFile, int duration) async {
    setState(() => _isRecordingVoice = false);
    try {
      final text = _messageController.text.trim();
      await ref
          .read(chatControllerProvider(widget.roomId).notifier)
          .uploadAndSendVoice(voiceFile, duration, text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Failed to send voice message: $e');
    }
  }

  void _deleteMessage(String messageId) {
    ref
        .read(chatControllerProvider(widget.roomId).notifier)
        .deleteMessage(messageId);
  }

  bool _shouldShowDateSeparator(int index, List messages) {
    if (index == 0) return true;
    final currentDate = messages[index].createdAt;
    final previousDate = messages[index - 1].createdAt;
    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRoomCodeDialog() {
    if (widget.roomCode == null) {
      _showErrorSnackBar('Room code not available');
      return;
    }
    showDialog(
      context: context,
      builder: (context) =>
          RoomCodeDialog(roomCode: widget.roomCode!, roomName: widget.roomName),
    );
  }

  void _viewFullRoomPhoto(String imageUrl, String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(roomName, style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: Hero(
              tag: 'room_photo_${widget.roomId}',
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) =>
                      CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateRoomPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      final chatRepository = ref.read(chatRepositoryProvider);
      final photoUrl = await chatRepository.uploadRoomPhoto(
        File(pickedFile.path),
      );
      await chatRepository.updateRoom(widget.roomId, roomPhoto: photoUrl);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Room photo updated!')));
        ref.invalidate(roomDetailsProvider(widget.roomId));
        ref.invalidate(roomsControllerProvider);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Failed to update room photo: $e');
      }
    }
  }

  Future<void> _startCall(String callType) async {
    try {
      final myActiveCall = ref.read(myActiveCallProvider);
      if (myActiveCall != null) {
        _showErrorSnackBar('Already in a call');
        return;
      }
      final socketState = ref.read(socketControllerProvider);
      if (!socketState.isConnected) {
        await ref.read(socketControllerProvider.notifier).ensureConnected();
        await Future.delayed(Duration(milliseconds: 500));
        final newSocketState = ref.read(socketControllerProvider);
        if (!newSocketState.isConnected) {
          _showErrorSnackBar('Connection error. Please try again.');
          return;
        }
      }
      final hasPermissions = await PermissionService.requestCallPermissions(
        isVideoCall: callType == 'video',
      );
      if (!hasPermissions) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${callType == 'video' ? 'Camera and microphone' : 'Microphone'} permissions required',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => PermissionService.openAppSettings(),
            ),
          ),
        );
        return;
      }
      await ref
          .read(callControllerProvider.notifier)
          .startCall(
            roomId: widget.roomId,
            roomName: widget.roomName,
            callType: callType,
          );

      if (!mounted) return;

      final callState = ref.read(callControllerProvider);
      if (callState.error != null) {
        _showErrorSnackBar('Failed to start call: ${callState.error}');
        return;
      }

      if (callState.currentCall == null || callState.agoraToken == null) {
        _showErrorSnackBar('Failed to start call');
        return;
      }

      // ✅ CRITICAL FIX: Add .then() to refresh listener when returning
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(call: callState.currentCall!),
          fullscreenDialog: true,
        ),
      ).then((_) {
        // ✅ THIS IS THE KEY FIX: Refresh listener after returning from call
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔄 Returned from call - refreshing socket listener');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Force re-initialize the chat controller
        ref.invalidate(chatControllerProvider(widget.roomId));

        print('✅ Chat controller invalidated and will re-initialize');
      });
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed to start call: $e');
    }
  }

  Future<void> _joinOngoingCall(String callId) async {
    try {
      final hasPermissions = await PermissionService.requestCallPermissions(
        isVideoCall: false,
      );
      if (!hasPermissions) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission required'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => PermissionService.openAppSettings(),
            ),
          ),
        );
        return;
      }
      await ref
          .read(callControllerProvider.notifier)
          .joinCall(widget.roomId, callId);

      if (!mounted) return;

      final callState = ref.read(callControllerProvider);
      if (callState.error != null) {
        _showErrorSnackBar('Failed to join call: ${callState.error}');
        return;
      }

      if (callState.currentCall == null) {
        _showErrorSnackBar('Call not found');
        return;
      }

      // ✅ CRITICAL FIX: Add .then() here too
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(call: callState.currentCall!),
          fullscreenDialog: true,
        ),
      ).then((_) {
        // ✅ Refresh listener after returning from call
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔄 Returned from joined call - refreshing socket listener');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        ref.invalidate(chatControllerProvider(widget.roomId));

        print('✅ Chat controller invalidated and will re-initialize');
      });
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed to join call: $e');
    }
  }

  void _showMemberDetails() {
    final roomDetailsAsync = ref.read(roomDetailsProvider(widget.roomId));
    final currentUserIdAsync = ref.read(currentUserIdProvider);
    final theme = Theme.of(context);

    roomDetailsAsync.when(
      data: (roomDetails) {
        currentUserIdAsync.when(
          data: (currentUserId) {
            final socketState = ref.read(socketControllerProvider);
            final isAdmin = roomDetails.createdBy.id == currentUserId;

            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerTheme.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: roomDetails.roomPhoto != null
                                ? () {
                                    _viewFullRoomPhoto(
                                      roomDetails.roomPhoto!,
                                      widget.roomName,
                                    );
                                  }
                                : null,
                            child: Hero(
                              tag: 'room_photo_${widget.roomId}',
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                  color: theme.colorScheme.surface,
                                ),
                                child: roomDetails.roomPhoto != null
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: roomDetails.roomPhoto!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                Icons.group,
                                                size: 50,
                                                color: theme.iconTheme.color,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.group,
                                        size: 50,
                                        color: theme.iconTheme.color,
                                      ),
                              ),
                            ),
                          ),
                          if (isAdmin)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _updateRoomPhoto();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: theme.appBarTheme.foregroundColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        widget.roomName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.roomCode != null)
                      Center(
                        child: GestureDetector(
                          onTap: _showRoomCodeDialog,
                          child: Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.vpn_key,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Code: ${widget.roomCode}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.group,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Members (${roomDetails.members.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: roomDetails.members.length,
                        itemBuilder: (context, index) {
                          final member = roomDetails.members[index];
                          final isCreator =
                              member.id == roomDetails.createdBy.id;
                          final isMe = member.id == currentUserId;
                          final isOnline = socketState.onlineUsers.contains(
                            member.id,
                          );

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isCreator
                                      ? Colors.amber
                                      : theme.colorScheme.primary.withOpacity(
                                          0.2,
                                        ),
                                  backgroundImage: member.profilePhoto != null
                                      ? CachedNetworkImageProvider(
                                          member.profilePhoto!,
                                        )
                                      : null,
                                  child: member.profilePhoto == null
                                      ? Text(
                                          member.name[0].toUpperCase(),
                                          style: TextStyle(
                                            color: isCreator
                                                ? Colors.white
                                                : theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.surface,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              member.name + (isMe ? ' (You)' : ''),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.email,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                if (isOnline) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Online',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isCreator
                                ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    if (isAdmin)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteRoom();
                          },
                          icon: Icon(Icons.delete_outline),
                          label: Text('Delete Room'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _leaveRoom();
                          },
                          icon: Icon(Icons.exit_to_app),
                          label: Text('Leave Room'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
          loading: () {},
          error: (_, __) {},
        );
      },
      loading: () {
        _showErrorSnackBar('Loading room details...');
      },
      error: (error, _) {
        _showErrorSnackBar('Error loading room details');
      },
    );
  }

  Future<void> _deleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Room?'),
        content: Text(
          'This will permanently delete the room and all messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await ref
          .read(roomsControllerProvider.notifier)
          .deleteRoom(widget.roomId);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          _showErrorSnackBar('Failed to delete room');
        }
      }
    }
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Room?'),
        content: Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await ref
          .read(roomsControllerProvider.notifier)
          .leaveRoom(widget.roomId);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          _showErrorSnackBar('Failed to leave room');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(widget.roomId));
    final roomDetailsAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final socketState = ref.watch(socketControllerProvider);
    final theme = Theme.of(context);

    // ✅ ONLY SOURCE OF TRUTH: activeCallsProvider (socket-driven)
    final socketActiveCall = ref.watch(activeCallsProvider)[widget.roomId];
    final myActiveCall = ref.watch(myActiveCallProvider);

    // ✅ Show banner only if:
    // 1. There's an active call in this room (from socket)
    // 2. It's not MY active call
    final shouldShowBanner = socketActiveCall != null && myActiveCall == null;
    // Continue from: final shouldShowBanner = socketActiveCall != null && myActiveCall == null;

    final isInAnotherCall =
        myActiveCall != null && myActiveCall.roomId != widget.roomId;

    ref.listen(chatControllerProvider(widget.roomId), (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        Future.delayed(Duration(milliseconds: 300), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.appBarTheme.foregroundColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            roomDetailsAsync.when(
              data: (room) => GestureDetector(
                onTap: () {
                  if (room.roomPhoto != null)
                    _viewFullRoomPhoto(room.roomPhoto!, widget.roomName);
                },
                child: Hero(
                  tag: 'room_photo_${widget.roomId}',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    backgroundImage: room.roomPhoto != null
                        ? CachedNetworkImageProvider(room.roomPhoto!)
                        : null,
                    child: room.roomPhoto == null
                        ? Text(
                            widget.roomName[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.appBarTheme.foregroundColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              loading: () => CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              ),
              error: (_, __) => CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ],
        ),
        leadingWidth: 100,
        title: InkWell(
          onTap: _showMemberDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.roomName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.appBarTheme.foregroundColor,
                ),
              ),
              roomDetailsAsync.when(
                data: (room) => Text(
                  '${socketState.onlineUsers.length} online • ${room.members.length} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
                  ),
                ),
                loading: () =>
                    Text('Loading...', style: TextStyle(fontSize: 12)),
                error: (_, __) => SizedBox.shrink(),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: theme.appBarTheme.foregroundColor),
            onPressed: isInAnotherCall ? null : () => _startCall('audio'),
            tooltip: 'Audio Call',
          ),
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: isInAnotherCall ? null : () => _startCall('video'),
            tooltip: 'Video Call',
          ),
          if (widget.roomCode != null)
            IconButton(
              icon: Icon(Icons.share_outlined),
              onPressed: _showRoomCodeDialog,
              tooltip: 'Share',
            ),
        ],
      ),
      body: Column(
        children: [
          // ✅ CALL BANNER - Only shown for calls from socket
          if (shouldShowBanner)
            Container(
              color: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    socketActiveCall.callType == 'video'
                        ? Icons.videocam
                        : Icons.call,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Call in progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _joinOngoingCall(socketActiveCall.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Join',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          if (chatState.isUploading)
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          Expanded(
            child: chatState.isLoading
                ? Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                ? EmptyChatState()
                : ref
                      .watch(currentUserIdProvider)
                      .when(
                        data: (currentUserId) => ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatState.messages[index];
                            final isMe = message.sender.id == currentUserId;
                            final showDate = _shouldShowDateSeparator(
                              index,
                              chatState.messages,
                            );
                            return Column(
                              children: [
                                if (showDate)
                                  DateSeparator(date: message.createdAt),
                                MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                  showUsername: !isMe,
                                  onImageTap: message.hasImage
                                      ? () => _viewFullImage(message.imageUrl!)
                                      : null,
                                  onDelete: isMe && message.canBeDeleted
                                      ? () => _deleteMessage(message.id)
                                      : null,
                                ),
                              ],
                            );
                          },
                        ),
                        loading: () =>
                            Center(child: CircularProgressIndicator()),
                        error: (_, __) =>
                            Center(child: Text('Error loading user')),
                      ),
          ),
          if (socketState.typingUsers.isNotEmpty)
            TypingIndicator(typingUsers: socketState.typingUsers),
          if (_isRecordingVoice)
            VoiceRecorderWidget(
              onVoiceSend: _sendVoiceMessage,
              onCancel: _cancelVoiceRecording,
            )
          else
            ChatInputField(
              controller: _messageController,
              onSend: _sendMessage,
              onImagePick: _showImageOptions,
              onVoiceRecord: _startVoiceRecording,
              isUploading: chatState.isUploading,
            ),
        ],
      ),
    );
  }
}
