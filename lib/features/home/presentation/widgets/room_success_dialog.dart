// widgets/room_success_dialog.dart
import 'package:flutter/material.dart';
import 'package:baatkaro/features/chats/presentation/widgets/room_code_card.dart';

class RoomSuccessDialog extends StatelessWidget {
  final String roomCode;
  final String roomName;
  final String roomId;
  final VoidCallback onEnterRoom;

  const RoomSuccessDialog({
    Key? key,
    required this.roomCode,
    required this.roomName,
    required this.roomId,
    required this.onEnterRoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: theme.appBarTheme.foregroundColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Created!',
                        style: TextStyle(
                          color: theme.appBarTheme.foregroundColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Share the code with others',
                        style: TextStyle(
                          color: theme.appBarTheme.foregroundColor
                              ?.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          RoomCodeShareCard(
            roomCode: roomCode,
            roomName: roomName,
            showTitle: false,
            compact: true,
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEnterRoom,
                icon: Icon(Icons.arrow_forward),
                label: Text('Enter Room'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}