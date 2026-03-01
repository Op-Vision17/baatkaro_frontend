// features/chats/presentation/widgets/chat/call_message_bubble.dart

import 'package:baatkaro/features/chats/data/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;

  const CallMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onTap,
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

  IconData _getCallIcon() {
    if (message.callData == null) return Icons.call;
    return message.callData!.callType == 'video' 
        ? Icons.videocam 
        : Icons.call;
  }

  Color _getCallColor(BuildContext context) {
    if (message.callData == null) return Colors.grey;
    
    final callData = message.callData!;
    final theme = Theme.of(context);
    
    if (callData.isOngoing) {
      return Colors.green;
    } else if (callData.isMissed) {
      return Colors.red;
    } else if (callData.isEnded) {
      return theme.colorScheme.primary;
    } else {
      return Colors.blue;
    }
  }

  String _getStatusText() {
    if (message.callData == null) return 'Call';
    
    final callData = message.callData!;
    
    if (callData.isOngoing) {
      return 'Ongoing • ${callData.participantCount} participant${callData.participantCount > 1 ? 's' : ''}';
    } else if (callData.isMissed) {
      return 'Missed Call';
    } else if (callData.isEnded && callData.duration != null) {
      return 'Duration: ${callData.durationText}';
    } else {
      return 'Call Started';
    }
  }

  String _getCallTypeText() {
    if (message.callData == null) return 'Call';
    return message.callData!.callType == 'video' ? 'Video Call' : 'Audio Call';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callColor = _getCallColor(context);
    final canJoin = message.callData?.isJoinable ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: canJoin ? onTap : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: callColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Call icon and type
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: callColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCallIcon(),
                          color: callColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getCallTypeText(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Started by ${message.callData?.initiatorName ?? message.sender.name}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Status and duration
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: callColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.callData?.isOngoing ?? false
                              ? Icons.radio_button_checked
                              : message.callData?.isMissed ?? false
                                  ? Icons.call_missed
                                  : Icons.check_circle_outline,
                          size: 14,
                          color: callColor,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: callColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Join button for ongoing calls
                  if (canJoin && onTap != null) ...[
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: Icon(Icons.phone, size: 18),
                        label: Text(
                          'Join Call',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Timestamp
                  SizedBox(height: 8),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}