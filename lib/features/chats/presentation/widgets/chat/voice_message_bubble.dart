import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String? voiceUrl;
  final int duration;
  final bool isMe;
  final bool isUploading;
  final double uploadProgress;

  const VoiceMessageBubble({
    required this.voiceUrl,
    required this.duration,
    required this.isMe,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    Key? key,
  }) : super(key: key);

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.isUploading || widget.voiceUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.voiceUrl!));
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _totalDuration.inSeconds > 0
        ? _currentPosition.inSeconds / _totalDuration.inSeconds
        : 0.0;

    // Colors based on sender
    final backgroundColor = widget.isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final foregroundColor = widget.isMe
        ? theme.appBarTheme.foregroundColor ?? Colors.white
        : theme.textTheme.bodyLarge?.color ?? Colors.black;
    final buttonBg = widget.isMe
        ? theme.appBarTheme.foregroundColor ?? Colors.white
        : theme.colorScheme.primary;
    final buttonFg = widget.isMe
        ? theme.colorScheme.primary
        : theme.appBarTheme.foregroundColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: buttonBg,
                shape: BoxShape.circle,
              ),
              child: widget.isUploading
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        value: widget.uploadProgress,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(buttonFg),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: buttonFg,
                      size: 20,
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.isUploading
                        ? widget.uploadProgress
                        : progress,
                    backgroundColor: foregroundColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isUploading
                      ? 'Uploading ${(widget.uploadProgress * 100).toInt()}%'
                      : (_isPlaying
                            ? _formatDuration(_currentPosition)
                            : _formatDuration(_totalDuration)),
                  style: TextStyle(fontSize: 12, color: foregroundColor),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Microphone icon
          Icon(Icons.mic, size: 16, color: foregroundColor),
        ],
      ),
    );
  }
}
