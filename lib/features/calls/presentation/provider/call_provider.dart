// call_provider.dart - FIXED: Stream subscriptions instead of callbacks

import 'dart:async';
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

final activeCallsProvider = StateProvider<Map<String, CallModel>>((ref) => {});
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
  
  // ✅ Stream subscriptions
  StreamSubscription<Map<String, dynamic>>? _incomingCallSubscription;
  StreamSubscription<Map<String, dynamic>>? _callStartedSubscription;
  StreamSubscription<Map<String, dynamic>>? _userJoinedSubscription;
  StreamSubscription<Map<String, dynamic>>? _userLeftSubscription;
  StreamSubscription<Map<String, dynamic>>? _callEndedSubscription;
  StreamSubscription<Map<String, dynamic>>? _callErrorSubscription;

  CallController(this._callRepository, this._socketRepository, this._ref)
    : super(CallState()) {
    _setupCallListeners();
  }

  void _setupCallListeners() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎧 Setting up call stream subscriptions');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // ✅ Subscribe to call streams
    _incomingCallSubscription = _socketRepository.incomingCallStream.listen(
      _handleIncomingCall,
      onError: (error) => print('❌ Incoming call stream error: $error'),
    );

    _callStartedSubscription = _socketRepository.callStartedStream.listen(
      _handleCallStarted,
      onError: (error) => print('❌ Call started stream error: $error'),
    );

    _userJoinedSubscription = _socketRepository.userJoinedCallStream.listen(
      _handleUserJoined,
      onError: (error) => print('❌ User joined stream error: $error'),
    );

    _userLeftSubscription = _socketRepository.userLeftCallStream.listen(
      _handleUserLeft,
      onError: (error) => print('❌ User left stream error: $error'),
    );

    _callEndedSubscription = _socketRepository.callEndedStream.listen(
      _handleCallEnded,
      onError: (error) => print('❌ Call ended stream error: $error'),
    );

    _callErrorSubscription = _socketRepository.callErrorStream.listen(
      _handleCallError,
      onError: (error) => print('❌ Call error stream error: $error'),
    );

    print('✅ Call stream subscriptions setup complete');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STREAM HANDLERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _handleIncomingCall(Map<String, dynamic> data) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📞 INCOMING CALL (Stream)');
    print('   Call ID: ${data['callId']}');
    print('   Room ID: ${data['roomId']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final call = CallModel.fromJson(data);

      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final currentUserId = prefs.getString('userId');

      final isMyOutgoingCall = call.caller.id == currentUserId;
      final myCall = _ref.read(myActiveCallProvider);
      final isMyActiveCall = myCall != null && myCall.roomId == call.roomId;

      if (!isMyOutgoingCall && !isMyActiveCall) {
        print('   ✅ Adding to activeCallsProvider');
        final activeCalls = _ref.read(activeCallsProvider.notifier);
        activeCalls.update((state) => {...state, call.roomId: call});
      } else {
        print('   ⏭️ Skipping (my call)');
      }
    } catch (e) {
      print('❌ Error handling incoming call: $e');
    }
  }

  void _handleCallStarted(Map<String, dynamic> data) {
    print('📞 CALL STARTED (Stream): ${data['callId']}');

    try {
      final callId = data['callId']?.toString();
      final roomId = data['roomId']?.toString();

      if (callId != null && 
          roomId != null && 
          state.currentCall != null &&
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
        print('✅ My call updated with real ID');
      }
    } catch (e) {
      print('❌ Error handling call started: $e');
    }
  }

  void _handleUserJoined(Map<String, dynamic> data) {
    print('✅ USER JOINED (Stream): ${data['user']?['name']}');

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
      print('❌ Error handling user joined: $e');
    }
  }

  void _handleUserLeft(Map<String, dynamic> data) {
    print('🚪 USER LEFT (Stream): ${data['user']?['id']}');

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
      print('❌ Error handling user left: $e');
    }
  }

  void _handleCallEnded(Map<String, dynamic> data) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏁 CALL ENDED (Stream)');
    print('   Call ID: ${data['callId']}');
    print('   Room ID: ${data['roomId']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final roomId = data['roomId']?.toString();

    if (roomId != null) {
      // Remove from active calls
      final activeCalls = _ref.read(activeCallsProvider.notifier);
      activeCalls.update((state) {
        final newState = Map<String, CallModel>.from(state);
        newState.remove(roomId);
        return newState;
      });

      // Clear my active call
      final myCall = _ref.read(myActiveCallProvider);
      if (myCall != null && myCall.roomId == roomId) {
        _ref.read(myActiveCallProvider.notifier).state = null;
      }
    }

    // End my call state
    if (state.currentCall != null && state.currentCall!.roomId == roomId) {
      _endCall();
    }
  }

  void _handleCallError(Map<String, dynamic> data) {
    print('❌ CALL ERROR (Stream): ${data['message']}');

    state = state.copyWith(
      error: data['message']?.toString() ?? 'Call error occurred',
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CALL ACTIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> startCall({
    required String roomId,
    required String roomName,
    required String callType,
  }) async {
    try {
      print('📞 Starting $callType call in room: $roomId');

      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('userName') ?? 'You';

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

      _socketRepository.startCall(roomId, callType);

      // Generate Agora token
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

      print('✅ Call started');
    } catch (e) {
      print('❌ Error starting call: $e');
      state = state.copyWith(
        error: e.toString(),
        isRinging: false,
        currentCall: null,
      );
      _ref.read(myActiveCallProvider.notifier).state = null;
    }
  }

  Future<void> joinCall(String roomId, String callId) async {
    try {
      print('✅ Joining call: $callId');

      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final userId = prefs.getString('userId') ?? '';

      final activeCalls = _ref.read(activeCallsProvider);
      final call = activeCalls[roomId];

      if (call == null) {
        state = state.copyWith(error: 'Call not found');
        return;
      }

      // Remove from active calls (now it's my call)
      _ref.read(activeCallsProvider.notifier).update((state) {
        final newState = Map<String, CallModel>.from(state);
        newState.remove(roomId);
        return newState;
      });

      state = state.copyWith(currentCall: call, isRinging: false);
      _ref.read(myActiveCallProvider.notifier).state = call;

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
    } catch (e) {
      print('❌ Error joining call: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  void rejectCall(String roomId, String callId) {
    print('❌ Rejecting call: $callId');

    _socketRepository.rejectCall(roomId, callId);

    final activeCalls = _ref.read(activeCallsProvider.notifier);
    activeCalls.update((state) {
      final newState = Map<String, CallModel>.from(state);
      newState.remove(roomId);
      return newState;
    });
  }

  void leaveCall() {
    if (state.currentCall == null) return;

    print('🚪 Leaving call: ${state.currentCall!.id}');

    _socketRepository.leaveCall(
      state.currentCall!.roomId,
      state.currentCall!.id,
    );

    _endCall();
  }

  void toggleAudio() {
    if (state.currentCall == null) return;

    final newMutedState = !state.isMuted;
    _socketRepository.toggleAudio(state.currentCall!.roomId, newMutedState);
    state = state.copyWith(isMuted: newMutedState);
  }

  void toggleVideo() {
    if (state.currentCall == null) return;

    final newVideoState = !state.isVideoOff;
    _socketRepository.toggleVideo(state.currentCall!.roomId, newVideoState);
    state = state.copyWith(isVideoOff: newVideoState);
  }

  void _endCall() {
    print('🏁 Ending call');
    state = CallState();
    _ref.read(myActiveCallProvider.notifier).state = null;
  }

  CallModel? getActiveCallForRoom(String roomId) {
    final activeCalls = _ref.read(activeCallsProvider);
    return activeCalls[roomId];
  }

  @override
  void dispose() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗑️ Disposing CallController');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // ✅ Cancel all stream subscriptions
    _incomingCallSubscription?.cancel();
    _callStartedSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _callEndedSubscription?.cancel();
    _callErrorSubscription?.cancel();
    
    print('✅ Stream subscriptions cancelled');
    
    super.dispose();
  }
}

final callControllerProvider = StateNotifierProvider<CallController, CallState>(
  (ref) {
    final callRepository = ref.watch(callRepositoryProvider);
    final socketRepository = ref.watch(socketRepositoryProvider);
    return CallController(callRepository, socketRepository, ref);
  },
);