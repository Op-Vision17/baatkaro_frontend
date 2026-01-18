import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File voiceFile, int duration) onVoiceSend;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    required this.onVoiceSend,
    required this.onCancel,
    Key? key,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  FlutterSoundRecorder? _audioRecorder;
  int _recordDuration = 0;
  Timer? _timer;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder
        ?.stopRecorder()
        .then((_) {
          return _audioRecorder?.closeRecorder();
        })
        .catchError((e) {
          print('Error closing recorder: $e');
        });
    super.dispose();
  }

  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
    await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        widget.onCancel();
        return;
      }

      final directory = await getTemporaryDirectory();
      _audioPath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder!.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (mounted) {
          setState(() => _recordDuration++);
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder?.stopRecorder();
      _timer?.cancel();

      if (_audioPath != null && mounted) {
        widget.onVoiceSend(File(_audioPath!), _recordDuration);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder?.stopRecorder();
      _timer?.cancel();

      if (_audioPath != null) {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (mounted) {
        widget.onCancel();
      }
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(top: BorderSide(color: theme.dividerTheme.color ?? Colors.grey)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            IconButton(
              onPressed: _cancelRecording,
              icon: const Icon(Icons.delete, color: Colors.red),
              padding: EdgeInsets.zero,
            ),

            const SizedBox(width: 8),

            // Recording indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 12),

            // Duration
            Text(
              _formatDuration(_recordDuration),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),

            const Spacer(),

            // Send button
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _stopRecording,
                icon: Icon(
                  Icons.send,
                  color: theme.appBarTheme.foregroundColor,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}