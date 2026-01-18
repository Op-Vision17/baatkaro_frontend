import 'package:baatkaro/features/chats/presentation/widgets/room_code_card.dart';
import 'package:flutter/material.dart';

class RoomCodeDialog extends StatelessWidget {
  final String roomCode;
  final String roomName;

  const RoomCodeDialog({
    Key? key,
    required this.roomCode,
    required this.roomName,
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  color: theme.appBarTheme.foregroundColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Room Code',
                  style: TextStyle(
                    color: theme.appBarTheme.foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}