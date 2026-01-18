// widgets/create_room_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_provider.dart';

class CreateRoomDialog extends ConsumerStatefulWidget {
  final Function(String roomCode, String roomName, String roomId) onRoomCreated;

  const CreateRoomDialog({
    Key? key,
    required this.onRoomCreated,
  }) : super(key: key);

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final room = await ref
        .read(roomsControllerProvider.notifier)
        .createRoom(_controller.text);

    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.pop(context);

    if (room != null) {
      widget.onRoomCreated(
        room['roomCode'],
        room['name'],
        room['_id'],
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
                child: Text('Error: ${error ?? "Failed to create room"}'),
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
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_box, color: theme.colorScheme.primary),
          ),
          SizedBox(width: 12),
          Text('Create New Room', style: theme.textTheme.titleLarge),
        ],
      ),
      content: TextField(
        controller: _controller,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: 'Room Name',
          hintText: 'Enter a name for your room',
          prefixIcon: Icon(Icons.meeting_room),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _createRoom(),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createRoom,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.check),
          label: Text(_isLoading ? 'Creating...' : 'Create'),
          style: ElevatedButton.styleFrom(
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