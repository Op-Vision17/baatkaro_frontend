import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class RoomCodeShareCard extends StatelessWidget {
  final String roomCode;
  final String roomName;
  final bool showTitle;
  final bool compact;

  const RoomCodeShareCard({
    Key? key,
    required this.roomCode,
    required this.roomName,
    this.showTitle = true,
    this.compact = false,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code copied: $roomCode'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareRoomCode() {
    Share.share(
      '🎉 Join my room "$roomName" on Baatkro!\n\n'
      '📱 Room Code: $roomCode\n\n'
      'Enter this code in the app to join the chat!',
      subject: 'Join my Baatkro room',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primary,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle) ...[
              Icon(
                Icons.vpn_key,
                size: 48,
                color: theme.appBarTheme.foregroundColor,
              ),
              SizedBox(height: 16),
              Text(
                'Room Code',
                style: TextStyle(
                  color: theme.appBarTheme.foregroundColor?.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
            ],
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),

              child: Text(
                roomCode,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                  label: Text(
                    'Copy',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _shareRoomCode,
                  icon: Icon(Icons.share, color: theme.colorScheme.primary),
                  label: Text(
                    'Share',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            roomCode,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Share this code with others to invite them',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _copyToClipboard(context),
                icon: Icon(Icons.copy),
                label: Text('Copy'),
              ),
              ElevatedButton.icon(
                onPressed: _shareRoomCode,
                icon: Icon(Icons.share),
                label: Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
