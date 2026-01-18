// call_provider.dart - FIXED: Single source of truth, no duplicate listeners

import 'package:baatkaro/features/calls/data/model/call_model.dart';
import 'package:baatkaro/features/calls/data/repository/call_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../chats/data/repositories/socket_repository.dart';
import '../../../chats/presentation/providers/socket_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final callRepositoryProvider = Provider<CallRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CallRepository(dio);
});

// ✅ SINGLE SOURCE OF TRUTH: Active calls from socket ONLY
// This is populated by socket events (incoming_call) from backend
final activeCallsProvider = StateProvider<Map<String, CallModel>>((ref) => {});

// Current user's active call (the one they're in)
final myActiveCallProvider = StateProvider<CallModel?>((ref) => null);

// Call State for UI
class CallState {
  final bool isInCall;
  final bool isRinging;
  final bool isMuted;
  final bool isVideoOff;
  final String? error;
  final CallModel? currentCall;
  final List<CallUser> participants;
  final String? agoraToken;
  final String? agoraChannel;
  final int? agoraUid;

  CallState({
    this.isInCall = false,
    this.isRinging = false,
    this.isMuted = false,
    this.isVideoOff = false,
    this.error,
    this.currentCall,
    this.participants = const [],
    this.agoraToken,
    this.agoraChannel,
    this.agoraUid,
  });

  CallState copyWith({
    bool? isInCall,
    bool? isRinging,
    bool? isMuted,
    bool? isVideoOff,
    String? error,
    CallModel? currentCall,
    List<CallUser>? participants,
    String? agoraToken,
    String? agoraChannel,
    int? agoraUid,
  }) {
    return CallState(
      isInCall: isInCall ?? this.isInCall,
      isRinging: isRinging ?? this.isRinging,
      isMuted: isMuted ?? this.isMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      error: error,
      currentCall: currentCall ?? this.currentCall,
      participants: participants ?? this.participants,
      agoraToken: agoraToken ?? this.agoraToken,
      agoraChannel: agoraChannel ?? this.agoraChannel,
      agoraUid: agoraUid ?? this.agoraUid,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CALL CONTROLLER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CallController extends StateNotifier<CallState> {
  final CallRepository _callRepository;
  final SocketRepository _socketRepository;
  final Ref _ref;
  bool _listenersSetup = false;

  CallController(this._callRepository, this._socketRepository, this._ref)
    : super(CallState()) {
    _setupCallListeners();
  }

  void _setupCallListeners() {
    if (_listenersSetup) {
      print('⚠️ Call listeners already setup, skipping');
      return;
    }

    print('🎧 Setting up call event listeners...');

    // ✅ Re-register listeners on socket reconnect
    _socketRepository.onConnected = () {
      print('✅ Socket reconnected - re-registering call listeners');
      _registerCallListeners();
    };

    _registerCallListeners();
    _listenersSetup = true;
    print('✅ Call listeners setup complete');
  }

  void _registerCallListeners() {
    print('📞 Registering call event listeners...');

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📞 INCOMING CALL
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _socketRepository.onIncomingCall((data) async {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📞 INCOMING CALL EVENT');
      print('   Call ID: ${data['callId']}');
      print('   Room ID: ${data['roomId']}');
      print('   Caller: ${data['caller']?['name']}');
      print('   Status: ${data['status']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      try {
        final call = CallModel.fromJson(data);

        // Get current user ID
        final prefs = await _ref.read(sharedPreferencesProvider.future);
        final currentUserId = prefs.getString('userId');

        print('   Current User: $currentUserId');
        print('   Caller ID: ${call.caller.id}');

        // ✅ Check if I'm the one who initiated this call
        final isMyOutgoingCall = call.caller.id == currentUserId;

        // ✅ Check if I'm already in this call
        final myCall = _ref.read(myActiveCallProvider);
        final isMyActiveCall = myCall != null && myCall.roomId == call.roomId;

        print('   Is my outgoing call: $isMyOutgoingCall');
        print('   Is my active call: $isMyActiveCall');

        // ✅ CRITICAL LOGIC: Only add to activeCallsProvider if:
        // 1. NOT my outgoing call (I didn't initiate it)
        // 2. NOT already my active call (I'm not already in it)
        if (!isMyOutgoingCall && !isMyActiveCall) {
          print('   ✅ Adding to activeCallsProvider (incoming from others)');

          final activeCalls = _ref.read(activeCallsProvider.notifier);
          activeCalls.update((state) => {...state, call.roomId: call});

          print('   ✅ Active calls updated');
          print(
            '   Total active calls: ${_ref.read(activeCallsProvider).length}',
          );
        } else {
          if (isMyOutgoingCall) {
            print('   ⏭️ Skipping: This is MY outgoing call');
          }
          if (isMyActiveCall) {
            print('   ⏭️ Skipping: I\'m already in this call');
          }
        }
      } catch (e, stackTrace) {
        print('❌ Error processing incoming call: $e');
        print('Stack trace: $stackTrace');
      }
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ✅ CALL STARTED (backend confirmed)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _socketRepository.onCallStarted((data) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📞 CALL STARTED EVENT');
      print('   Call ID: ${data['callId']}');
      print('   Room ID: ${data['roomId']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      try {
        final callId = data['callId']?.toString();
        final roomId = data['roomId']?.toString();

        if (callId != null && roomId != null) {
          // Update MY call with real ID if this is my outgoing call
          if (state.currentCall != null &&
              state.currentCall!.roomId == roomId) {
            final updatedCall = CallModel(
              id: callId,
              roomId: state.currentCall!.roomId,
              roomName: state.currentCall!.roomName,
              callType: state.currentCall!.callType,
              caller: state.currentCall!.caller,
              participants: state.currentCall!.participants,
              status: 'ongoing',
              startTime: DateTime.now(),
            );

            state = state.copyWith(
              currentCall: updatedCall,
              isInCall: true,
              isRinging: false,
            );

            _ref.read(myActiveCallProvider.notifier).state = updatedCall;

            print('✅ My call updated with real ID: $callId');
          }
        }
      } catch (e) {
        print('❌ Error processing call started: $e');
      }
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 👥 USER JOINED CALL
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _socketRepository.onUserJoinedCall((data) {
      print('✅ USER JOINED CALL: ${data['user']?['name']}');

      try {
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final user = CallUser.fromJson(userData);

          if (!state.participants.any((p) => p.id == user.id)) {
            state = state.copyWith(participants: [...state.participants, user]);
            print('✅ Added participant: ${user.name}');
          }
        }
      } catch (e) {
        print('❌ Error processing user joined: $e');
      }
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🚪 USER LEFT CALL
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _socketRepository.onUserLeftCall((data) {
      print('🚪 USER LEFT CALL: ${data['user']?['id']}');

      try {
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final userId = userData['id']?.toString();

          if (userId != null) {
            state = state.copyWith(
              participants: state.participants
                  .where((p) => p.id != userId)
                  .toList(),
            );
            print('✅ Removed participant: $userId');
          }
        }
      } catch (e) {
        print('❌ Error processing user left: $e');
      }
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🏁 CALL ENDED
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _socketRepository.onCallEnded((data) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🏁 CALL ENDED EVENT');
      print('   Call ID: ${data['callId']}');
      print('   Room ID: ${data['roomId']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final roomId = data['roomId']?.toString();

      if (roomId != null) {
        print('   Cleaning up call for room: $roomId');

        // ✅ Remove from activeCallsProvider
        final activeCalls = _ref.read(activeCallsProvider.notifier);
        activeCalls.update((state) {
          final newState = Map<String, CallModel>.from(state);
          newState.remove(roomId);
          print(
            '   ✅ Removed from active calls. Remaining: ${newState.keys.toList()}',
          );
          return newState;
        });

        // ✅ Clear myActiveCallProvider if this was my call
        final myCall = _ref.read(myActiveCallProvider);
        if (myCall != null && myCall.roomId == roomId) {
          print('   ✅ Clearing myActiveCallProvider');
          _ref.read(myActiveCallProvider.notifier).state = null;
        }
      }

      // ✅ End MY call state if I'm in this room
      if (state.currentCall != null && state.currentCall!.roomId == roomId) {
        print('   This was my active call, ending it');
        _endCall();
      }
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ❌ CALL ERROR
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _socketRepository.onCallError((data) {
      print('❌ CALL ERROR: ${data['message']}');

      state = state.copyWith(
        error: data['message']?.toString() ?? 'Call error occurred',
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📞 START CALL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> startCall({
    required String roomId,
    required String roomName,
    required String callType,
  }) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📞 Starting $callType call in room: $roomId');

      // Get current user info
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('userName') ?? 'You';

      // Create temporary call model
      final tempCall = CallModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        roomName: roomName,
        callType: callType,
        caller: CallUser(id: userId, name: userName),
        participants: [],
        status: 'ringing',
        startTime: DateTime.now(),
      );

      state = state.copyWith(isRinging: true, currentCall: tempCall);
      _ref.read(myActiveCallProvider.notifier).state = tempCall;

      print('   ✅ Set myActiveCallProvider (outgoing call)');

      // Emit socket event
      _socketRepository.startCall(roomId, callType);

      // Generate Agora token immediately
      try {
        final tokenData = await _callRepository.generateAgoraToken(
          channelName: roomId,
          uid: userId.hashCode,
        );

        state = state.copyWith(
          agoraToken: tokenData['token'],
          agoraChannel: roomId,
          agoraUid: userId.hashCode,
          isInCall: true,
          isRinging: false,
        );

        print('✅ Call started, Agora token generated');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } catch (tokenError) {
        print('❌ Failed to generate Agora token: $tokenError');
        state = state.copyWith(
          error: 'Failed to generate call token',
          isRinging: false,
          currentCall: null,
        );
        _ref.read(myActiveCallProvider.notifier).state = null;
      }
    } catch (e) {
      print('❌ Error starting call: $e');
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isRinging: false,
        currentCall: null,
      );
      _ref.read(myActiveCallProvider.notifier).state = null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ JOIN CALL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> joinCall(String roomId, String callId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ Joining call: $callId in room: $roomId');

      // Get current user info
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final userId = prefs.getString('userId') ?? '';

      // Get call from active calls
      final activeCalls = _ref.read(activeCallsProvider);
      final call = activeCalls[roomId];

      if (call == null) {
        print('❌ No active call found for room: $roomId');
        state = state.copyWith(error: 'Call not found');
        return;
      }

      print('   ✅ Found call in activeCallsProvider');

      // ✅ Remove from activeCallsProvider when joining (it's now MY call)
      _ref.read(activeCallsProvider.notifier).update((state) {
        final newState = Map<String, CallModel>.from(state);
        newState.remove(roomId);
        print('   ✅ Removed from activeCallsProvider (now my call)');
        return newState;
      });

      // Update state
      state = state.copyWith(currentCall: call, isRinging: false);
      _ref.read(myActiveCallProvider.notifier).state = call;

      print('   ✅ Set myActiveCallProvider (joined call)');

      // Emit socket event
      _socketRepository.joinCall(roomId, callId);

      // Generate Agora token
      final tokenData = await _callRepository.generateAgoraToken(
        channelName: roomId,
        uid: userId.hashCode,
      );

      state = state.copyWith(
        isInCall: true,
        agoraToken: tokenData['token'],
        agoraChannel: roomId,
        agoraUid: userId.hashCode,
      );

      print('✅ Joined call successfully');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ Error joining call: $e');
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ❌ REJECT CALL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void rejectCall(String roomId, String callId) {
    print('❌ Rejecting call: $callId');

    _socketRepository.rejectCall(roomId, callId);

    // Remove from active calls
    final activeCalls = _ref.read(activeCallsProvider.notifier);
    activeCalls.update((state) {
      final newState = Map<String, CallModel>.from(state);
      newState.remove(roomId);
      return newState;
    });

    print('✅ Call rejected and removed from activeCallsProvider');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚪 LEAVE CALL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void leaveCall() {
    if (state.currentCall == null) return;

    print('🚪 Leaving call: ${state.currentCall!.id}');

    _socketRepository.leaveCall(
      state.currentCall!.roomId,
      state.currentCall!.id,
    );

    _endCall();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔇 TOGGLE AUDIO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void toggleAudio() {
    if (state.currentCall == null) return;

    final newMutedState = !state.isMuted;

    print('🔇 Toggle audio: ${newMutedState ? "MUTED" : "UNMUTED"}');

    _socketRepository.toggleAudio(state.currentCall!.roomId, newMutedState);

    state = state.copyWith(isMuted: newMutedState);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📹 TOGGLE VIDEO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void toggleVideo() {
    if (state.currentCall == null) return;

    final newVideoState = !state.isVideoOff;

    print('📹 Toggle video: ${newVideoState ? "OFF" : "ON"}');

    _socketRepository.toggleVideo(state.currentCall!.roomId, newVideoState);

    state = state.copyWith(isVideoOff: newVideoState);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏁 END CALL (Cleanup)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _endCall() {
    print('🏁 Ending call...');

    state = CallState();
    _ref.read(myActiveCallProvider.notifier).state = null;

    print('✅ Call ended, state cleared');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 CHECK ACTIVE CALL IN ROOM
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CallModel? getActiveCallForRoom(String roomId) {
    final activeCalls = _ref.read(activeCallsProvider);
    return activeCalls[roomId];
  }
}

// Call Controller Provider
final callControllerProvider = StateNotifierProvider<CallController, CallState>(
  (ref) {
    final callRepository = ref.watch(callRepositoryProvider);
    final socketRepository = ref.watch(socketRepositoryProvider);
    return CallController(callRepository, socketRepository, ref);
  },
);
