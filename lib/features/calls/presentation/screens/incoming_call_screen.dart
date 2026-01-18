// incoming_call_screen.dart - FIXED VERSION with correct method calls

import 'package:baatkaro/features/calls/data/model/call_model.dart';
import 'package:baatkaro/features/calls/presentation/provider/call_provider.dart';
import 'package:baatkaro/features/calls/presentation/screens/call_screen.dart';
import 'package:baatkaro/shared/services/permission_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const IncomingCallScreen({Key? key, required this.call}) : super(key: key);

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-dismiss after 30 seconds if not answered
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        print('⏰ Call timeout - auto rejecting');
        _handleReject();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    print('✅ User accepted call: ${widget.call.id}');

    final hasPermissions = await PermissionService.requestCallPermissions(
      isVideoCall: widget.call.callType == 'video',
    );

    if (!hasPermissions) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permissions are required to join the call'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => PermissionService.openAppSettings(),
          ),
        ),
      );
      return;
    }

    // ✅ Join the call via CallController with required parameters
    await ref
        .read(callControllerProvider.notifier)
        .joinCall(
          widget.call.roomId, // ✅ Pass roomId
          widget.call.id, // ✅ Pass callId
        );

    if (!mounted) return;

    final callState = ref.read(callControllerProvider);

    if (callState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join call: ${callState.error}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (callState.currentCall == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call not found'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
      return;
    }

    // Navigate to call screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(call: callState.currentCall!),
      ),
    );
  }

  void _handleReject() {
    print('❌ User rejected call: ${widget.call.id}');

    // ✅ Reject call with required parameters
    ref
        .read(callControllerProvider.notifier)
        .rejectCall(
          widget.call.roomId, // ✅ Pass roomId
          widget.call.id, // ✅ Pass callId
        );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideoCall = widget.call.callType == 'video';

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 60),

              // Call type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideoCall ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isVideoCall ? 'Video Call' : 'Audio Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Spacer(),

              // Caller avatar with pulse animation
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.call.caller.avatar != null
                        ? CachedNetworkImage(
                            imageUrl: widget.call.caller.avatar!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.white.withOpacity(0.2),
                              child: Center(
                                child: Text(
                                  widget.call.caller.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.white.withOpacity(0.2),
                              child: Center(
                                child: Text(
                                  widget.call.caller.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.white.withOpacity(0.2),
                            child: Center(
                              child: Text(
                                widget.call.caller.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Caller name
              Text(
                widget.call.caller.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 8),

              // Room name
              Text(
                widget.call.roomName,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              SizedBox(height: 16),

              // Ringing text
              Text(
                'Incoming call...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),

              Spacer(),

              // Action buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _handleReject,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Decline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Accept button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _handleAccept,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
