import 'package:baatkaro/core/constants/app_constants.dart';
import 'package:baatkaro/features/calls/data/model/call_model.dart';
import 'package:baatkaro/features/calls/presentation/provider/call_provider.dart';
import 'package:baatkaro/features/calls/presentation/widgets/call_control_button.dart';
import 'package:baatkaro/features/calls/presentation/widgets/participant_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const CallScreen({Key? key, required this.call}) : super(key: key);

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  RtcEngine? _engine;
  bool _isInitialized = false;
  final Set<int> _remoteUids = {};

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    WakelockPlus.enable(); // Keep screen on during call
  }

  @override
  void dispose() {
    _cleanup();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    try {
      final appId = AppConstants.agoraAppId;

      if (appId.isEmpty) {
        debugPrint('❌ AGORA_APP_ID is missing from .env file');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration Error: App ID missing'),
            ),
          );
        }
        return;
      }
      final callState = ref.read(callControllerProvider);

      if (callState.agoraToken == null ||
          callState.agoraChannel == null ||
          callState.agoraUid == null) {
        print('❌ Missing Agora credentials');
        return;
      }

      print('🎥 Initializing Agora...');
      print('   Channel: ${callState.agoraChannel}');
      print('   UID: ${callState.agoraUid}');

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId, // ✅ Use the constant
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      // Setup event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('✅ Joined channel: ${connection.channelId}');
            setState(() => _isInitialized = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('✅ Remote user joined: $remoteUid');
            setState(() => _remoteUids.add(remoteUid));
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                print('🚪 Remote user offline: $remoteUid');
                setState(() => _remoteUids.remove(remoteUid));
              },
          onError: (ErrorCodeType err, String msg) {
            print('❌ Agora error: $err - $msg');
          },
        ),
      );

      // Enable audio
      await _engine!.enableAudio();

      // Enable video if video call
      if (widget.call.callType == 'video') {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      // Join channel
      await _engine!.joinChannel(
        token: callState.agoraToken!,
        channelId: callState.agoraChannel!,
        uid: callState.agoraUid!,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: widget.call.callType == 'video',
          publishMicrophoneTrack: true,
        ),
      );

      print('✅ Agora initialized successfully');
    } catch (e) {
      print('❌ Error initializing Agora: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _cleanup() async {
    print('🧹 Cleaning up Agora...');

    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;

    print('✅ Agora cleaned up');
  }

  void _handleEndCall() {
    ref.read(callControllerProvider.notifier).leaveCall();
    Navigator.pop(context);
  }

  void _handleToggleMute() {
    ref.read(callControllerProvider.notifier).toggleAudio();

    final isMuted = ref.read(callControllerProvider).isMuted;
    _engine?.muteLocalAudioStream(isMuted);
  }

  void _handleToggleVideo() {
    ref.read(callControllerProvider.notifier).toggleVideo();

    final isVideoOff = ref.read(callControllerProvider).isVideoOff;
    _engine?.muteLocalVideoStream(isVideoOff);
  }

  void _handleSwitchCamera() {
    _engine?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callControllerProvider);

    final isVideoCall = widget.call.callType == 'video';

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Video grid or audio-only view
              if (isVideoCall && _isInitialized)
                ParticipantGrid(
                  localUid: callState.agoraUid ?? 0,
                  remoteUids: _remoteUids.toList(),
                  engine: _engine,
                )
              else
                _buildAudioOnlyView(),

              // Top bar (room name, participants count)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.call.roomName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_remoteUids.length + 1} participant${_remoteUids.length != 0 ? 's' : ''}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      CallControlButton(
                        icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                        label: callState.isMuted ? 'Unmute' : 'Mute',
                        onPressed: _handleToggleMute,
                        backgroundColor: callState.isMuted
                            ? Colors.red
                            : Colors.white.withOpacity(0.2),
                        iconColor: Colors.white,
                      ),

                      // Video button (only for video calls)
                      if (isVideoCall)
                        CallControlButton(
                          icon: callState.isVideoOff
                              ? Icons.videocam_off
                              : Icons.videocam,
                          label: callState.isVideoOff
                              ? 'Video Off'
                              : 'Video On',
                          onPressed: _handleToggleVideo,
                          backgroundColor: callState.isVideoOff
                              ? Colors.red
                              : Colors.white.withOpacity(0.2),
                          iconColor: Colors.white,
                        ),

                      // Switch camera (only for video calls)
                      if (isVideoCall)
                        CallControlButton(
                          icon: Icons.switch_camera,
                          label: 'Switch',
                          onPressed: _handleSwitchCamera,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          iconColor: Colors.white,
                        ),

                      // End call button
                      CallControlButton(
                        icon: Icons.call_end,
                        label: 'End',
                        onPressed: _handleEndCall,
                        backgroundColor: Colors.red,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioOnlyView() {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large mic icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, size: 60, color: Colors.white),
            ),
            SizedBox(height: 32),
            Text(
              'Audio Call',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _remoteUids.isEmpty
                  ? 'Connecting...'
                  : '${_remoteUids.length + 1} in call',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
