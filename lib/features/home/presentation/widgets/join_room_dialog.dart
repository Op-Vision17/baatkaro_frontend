
// widgets/join_room_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_provider.dart';

class JoinRoomDialog extends ConsumerStatefulWidget {
  final Function(String roomId, String roomName, String roomCode) onRoomJoined;

  const JoinRoomDialog({
    Key? key,
    required this.onRoomJoined,
  }) : super(key: key);

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final room = await ref
        .read(roomsControllerProvider.notifier)
        .joinRoom(_controller.text);

    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.pop(context);

    if (room != null) {
      widget.onRoomJoined(
        room['_id'],
        room['name'],
        room['roomCode'],
      );
    } else {
      final error = ref.read(roomsControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Error: ${error ?? "Failed to join room"}'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.login, color: Colors.green),
          ),
          SizedBox(width: 12),
          Text('Join Room', style: theme.textTheme.titleLarge),
        ],
      ),
      content: TextField(
        controller: _controller,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: 'Room Code',
          hintText: 'Enter 6-digit code',
          prefixIcon: Icon(Icons.qr_code),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          counterText: '',
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
        onSubmitted: (_) => _joinRoom(),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _joinRoom,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.login),
          label: Text(_isLoading ? 'Joining...' : 'Join'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}