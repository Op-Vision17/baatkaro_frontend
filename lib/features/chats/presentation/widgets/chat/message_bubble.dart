// features/chats/presentation/widgets/chat/message_bubble.dart

import 'package:baatkaro/features/calls/presentation/widgets/call_message_bubble.dart';
import 'package:baatkaro/features/chats/data/models/message_model.dart';
import 'package:baatkaro/features/chats/presentation/widgets/chat/voice_message_bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'image_message_bubble.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showUsername;
  final VoidCallback? onImageTap;
  final VoidCallback? onDelete;
  final VoidCallback? onCallTap; // ✅ NEW: For joining ongoing calls

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showUsername = false,
    this.onImageTap,
    this.onDelete,
    this.onCallTap, // ✅ NEW
  }) : super(key: key);

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
    );

    if (messageDate == today) {
      return DateFormat('hh:mm a').format(localTime);
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('E hh:mm a').format(localTime);
    } else {
      return DateFormat('dd/MM/yy').format(localTime);
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Delete Message',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onDelete != null) {
                    onDelete!();
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Handle deleted messages
    if (message.isDeleted) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'This message was deleted',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ NEW: Handle call messages
    if (message.isCallMessage) {
      return CallMessageBubble(
        message: message,
        isMe: isMe,
        onTap: onCallTap,
      );
    }

    // ✅ EXISTING: Regular message bubbles (text, image, voice)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile photo for other users
          if (!isMe && showUsername) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              backgroundImage: message.sender.profilePhoto != null
                  ? CachedNetworkImageProvider(message.sender.profilePhoto!)
                  : null,
              child: message.sender.profilePhoto == null
                  ? Text(
                      message.sender.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 8),
          ],

          // Message content
          Flexible(
            child: GestureDetector(
              onLongPress: isMe && message.canBeDeleted
                  ? () => _showDeleteDialog(context)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Username
                    if (showUsername && !isMe)
                      Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          message.sender.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),

                    // Message bubble
                    Container(
                      decoration: BoxDecoration(
                        color: isMe
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: isMe
                              ? Radius.circular(20)
                              : Radius.circular(4),
                          bottomRight: isMe
                              ? Radius.circular(4)
                              : Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: isMe
                              ? Radius.circular(20)
                              : Radius.circular(4),
                          bottomRight: isMe
                              ? Radius.circular(4)
                              : Radius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Voice message
                            if (message.hasVoice ||
                                message.isUploading && message.voiceUrl != null)
                              VoiceMessageBubble(
                                voiceUrl: message.voiceUrl,
                                duration: message.voiceDuration ?? 0,
                                isMe: isMe,
                                isUploading: message.isUploading,
                                uploadProgress: message.uploadProgress,
                              ),

                            // Image message
                            if (message.hasImage ||
                                message.isUploading &&
                                    message.localFilePath != null)
                              ImageMessageBubble(
                                imageUrl: message.imageUrl,
                                localFilePath: message.localFilePath,
                                isUploading: message.isUploading,
                                uploadProgress: message.uploadProgress,
                                onTap: onImageTap,
                              ),

                            // Text message
                            if (message.text.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  message.hasImage || message.hasVoice ? 8 : 12,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe
                                        ? theme.appBarTheme.foregroundColor
                                        : theme.textTheme.bodyLarge?.color,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                            // Timestamp
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (message.isUploading) ...[
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: isMe
                                          ? theme.appBarTheme.foregroundColor
                                                ?.withOpacity(0.7)
                                          : theme.textTheme.bodySmall?.color,
                                    ),
                                    SizedBox(width: 4),
                                  ],
                                  Text(
                                    _formatTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? theme.appBarTheme.foregroundColor
                                                ?.withOpacity(0.7)
                                          : theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  if (isMe && !message.isUploading) ...[
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: theme.appBarTheme.foregroundColor
                                          ?.withOpacity(0.7),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (!isMe && showUsername) SizedBox(width: 40),
        ],
      ),
    );
  }
}