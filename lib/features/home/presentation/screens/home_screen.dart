// home_screen.dart - FIXED: Single source of truth for incoming calls

import 'package:baatkaro/features/auth/presentation/screens/login_screen.dart';
import 'package:baatkaro/features/auth/presentation/providers/auth_provider.dart';
import 'package:baatkaro/features/calls/data/model/call_model.dart';
import 'package:baatkaro/features/calls/presentation/provider/call_provider.dart';
import 'package:baatkaro/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:baatkaro/features/chats/presentation/screens/chat_screen.dart';
import 'package:baatkaro/features/home/presentation/screens/profile_screen.dart';
import 'package:baatkaro/features/home/presentation/widgets/logout_confirm_dialog.dart';
import 'package:baatkaro/features/home/presentation/widgets/room_list_otem.dart';
import 'package:baatkaro/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:baatkaro/shared/services/app_lifecycle_manger.dart';
import 'package:baatkaro/shared/services/network_connectivity_service.dart';
import 'package:baatkaro/shared/providers/notification_provider.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_provider.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/join_room_dialog.dart';
import '../widgets/room_success_dialog.dart';
import '../widgets/empty_rooms_view.dart';
import '../widgets/home_app_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ✅ Track which calls we've shown to prevent duplicates
  final Set<String> _shownCallIds = {};

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appLifecycleManagerProvider);
      ref.read(networkConnectivityServiceProvider);
      _setupNotificationHandler();
      _setupFCMCallHandler();
      ref.read(roomsControllerProvider.notifier).loadRooms();
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📞 SETUP FCM CALL HANDLER (For background notifications)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _setupFCMCallHandler() {
    final notificationService = ref.read(notificationServiceProvider);

    notificationService.onIncomingCall = (callData) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📞 FCM call notification received');
      print('   Call ID: ${callData['callId']}');
      print('   Room ID: ${callData['roomId']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // ✅ Give socket time to receive and populate activeCallsProvider
      Future.delayed(Duration(milliseconds: 1000), () {
        if (!mounted) return;

        final activeCalls = ref.read(activeCallsProvider);
        final roomId = callData['roomId'];

        print('   Active calls after delay: ${activeCalls.keys.toList()}');

        if (activeCalls.containsKey(roomId)) {
          final call = activeCalls[roomId]!;
          print('   ✅ Call found in activeCallsProvider');
          
          // Check if not already shown
          if (!_shownCallIds.contains(call.id)) {
            print('   📱 Showing incoming call screen from FCM');
            _showIncomingCallScreen(call);
          } else {
            print('   ⏭️ Call already shown, skipping');
          }
        } else {
          print('   ⚠️ Call not found in activeCallsProvider');
          print('   This is normal if call was already answered/rejected');
        }
      });
    };
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 SHOW INCOMING CALL SCREEN (Helper)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showIncomingCallScreen(CallModel call) {
    if (_shownCallIds.contains(call.id)) {
      print('   ⏭️ Call ${call.id} already shown, skipping duplicate');
      return;
    }

    _shownCallIds.add(call.id);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 SHOWING INCOMING CALL SCREEN');
    print('   Call ID: ${call.id}');
    print('   Room: ${call.roomName}');
    print('   Caller: ${call.caller.name}');
    print('   Type: ${call.callType}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    Future.microtask(() {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(call: call),
            fullscreenDialog: true,
          ),
        ).then((_) {
          print('   📱 Incoming call screen dismissed for ${call.id}');
        });
      }
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔔 SETUP CHAT NOTIFICATION HANDLER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _setupNotificationHandler() {
    ref.read(notificationControllerProvider.notifier).setOnNotificationTapped((
      roomId,
    ) {
      print('🔔 Notification tapped for room: $roomId');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            final roomsState = ref.read(roomsControllerProvider);
            final room = roomsState.rooms.firstWhere(
              (r) => r.id == roomId,
              orElse: () => roomsState.rooms.first,
            );

            return ChatScreen(
              roomId: roomId,
              roomName: room.name,
              roomCode: room.roomCode,
            );
          },
        ),
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏠 ROOM MANAGEMENT METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRoomDialog(
        onRoomCreated: (roomCode, roomName, roomId) {
          _showRoomCodeDialog(
            roomCode: roomCode,
            roomName: roomName,
            roomId: roomId,
          );
        },
      ),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => JoinRoomDialog(
        onRoomJoined: (roomId, roomName, roomCode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                roomId: roomId,
                roomName: roomName,
                roomCode: roomCode,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoomCodeDialog({
    required String roomCode,
    required String roomName,
    required String roomId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoomSuccessDialog(
        roomCode: roomCode,
        roomName: roomName,
        roomId: roomId,
        onEnterRoom: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                roomId: roomId,
                roomName: roomName,
                roomCode: roomCode,
              ),
            ),
          );
        },
      ),
    );
  }

  void _viewFullRoomPhoto(String imageUrl, String roomName, String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(roomName, style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: Hero(
              tag: 'room_photo_$roomId',
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) =>
                      CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => LogoutDialog(),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎨 BUILD METHOD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomsControllerProvider);
    final theme = Theme.of(context);

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ✅ SINGLE LISTENER: activeCallsProvider (socket-driven)
    // This is the ONLY place we listen for incoming calls
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ref.listen(activeCallsProvider, (previous, next) async {
      // Get current user ID
      final currentUserIdAsync = ref.read(currentUserIdProvider);
      final myActiveCall = ref.read(myActiveCallProvider);

      await currentUserIdAsync.whenData((currentUserId) {
        print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔍 Active calls changed');
        print('   Previous: ${previous?.keys.toList() ?? []}');
        print('   Current: ${next.keys.toList()}');
        print('   My user ID: $currentUserId');
        print('   My active call: ${myActiveCall?.roomId ?? "none"}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Check each active call
        next.forEach((roomId, call) {
          final wasShownBefore = _shownCallIds.contains(call.id);
          final isFromOtherUser = call.caller.id != currentUserId;
          final isRinging = call.status == 'ringing';
          final isNotMyActiveCall =
              myActiveCall == null || myActiveCall.roomId != roomId;

          print('\n   📞 Call in room: $roomId');
          print('      Call ID: ${call.id}');
          print('      Caller: ${call.caller.name} (${call.caller.id})');
          print('      Status: ${call.status}');
          print('      Checks:');
          print('         - Not shown before: ${!wasShownBefore}');
          print('         - From other user: $isFromOtherUser');
          print('         - Is ringing: $isRinging');
          print('         - Not my active call: $isNotMyActiveCall');

          // ✅ CRITICAL: Only show incoming call screen if ALL conditions met
          if (!wasShownBefore &&
              isFromOtherUser &&
              isRinging &&
              isNotMyActiveCall) {
            print('      ✅ SHOWING INCOMING CALL SCREEN');
            _showIncomingCallScreen(call);
          } else {
            print('      ⏭️ NOT showing (see checks above)');
          }
        });

        // ✅ Cleanup - remove calls that are no longer active
        _shownCallIds.removeWhere((callId) {
          final isStillActive = next.values.any((call) => call.id == callId);
          if (!isStillActive) {
            print('   🧹 Removing stale call from shown list: $callId');
          }
          return !isStillActive;
        });
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      });
    });

    return Scaffold(
      appBar: HomeAppBar(
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        },
        onNotificationsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationSettingsScreen(),
            ),
          );
        },
        onLogoutTap: _logout,
      ),
      body: roomsState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading rooms...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            )
          : roomsState.rooms.isEmpty
              ? EmptyRoomsView(
                  onCreateRoom: _showCreateRoomDialog,
                  onJoinRoom: _showJoinRoomDialog,
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(roomsControllerProvider.notifier).loadRooms(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: roomsState.rooms.length,
                    itemBuilder: (context, index) {
                      final room = roomsState.rooms[index];

                      return RoomListItem(
                        roomId: room.id,
                        roomName: room.name,
                        roomCode: room.roomCode,
                        roomPhoto: room.roomPhoto,
                        memberCount: room.members.length,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                roomId: room.id,
                                roomName: room.name,
                                roomCode: room.roomCode,
                              ),
                            ),
                          ).then(
                            (_) => ref
                                .read(roomsControllerProvider.notifier)
                                .loadRooms(),
                          );
                        },
                        onPhotoTap: room.roomPhoto != null
                            ? () => _viewFullRoomPhoto(
                                  room.roomPhoto!,
                                  room.name,
                                  room.id,
                                )
                            : null,
                      );
                    },
                  ),
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
              heroTag: 'join',
              onPressed: _showJoinRoomDialog,
              backgroundColor: Colors.green,
              icon: Icon(Icons.login),
              label: Text('Join'),
              elevation: 4,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
              heroTag: 'create',
              onPressed: _showCreateRoomDialog,
              icon: Icon(Icons.add),
              label: Text('Create'),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}