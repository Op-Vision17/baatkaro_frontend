// features/chats/presentation/widgets/chat/typing_indicator.dart

import 'package:baatkaro/features/chats/data/models/message_model.dart';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final List<TypingUser> typingUsers;

  const TypingIndicator({
    Key? key,
    required this.typingUsers,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTypingText() {
    if (widget.typingUsers.isEmpty) return '';

    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers[0].name} is typing...';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0].name} and ${widget.typingUsers[1].name} are typing...';
    } else {
      return '${widget.typingUsers[0].name} and ${widget.typingUsers.length - 1} others are typing...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Animated dots
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(animation: _controller, delay: 0.0),
                SizedBox(width: 4),
                _AnimatedDot(animation: _controller, delay: 0.33),
                SizedBox(width: 4),
                _AnimatedDot(animation: _controller, delay: 0.66),
              ],
            ),
          ),
          SizedBox(width: 8),
          // Typing text
          Flexible(
            child: Text(
              _getTypingText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController animation;
  final double delay;

  const _AnimatedDot({
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double value = (animation.value - delay) % 1.0;
        double scale = value < 0.5
            ? 1.0 + (value * 0.5)
            : 1.25 - ((value - 0.5) * 0.5);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}