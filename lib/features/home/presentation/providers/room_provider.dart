import 'package:baatkaro/features/home/data/model/room_model.dart';
import 'package:baatkaro/features/chats/data/repositories/chat_repository.dart';
import 'package:baatkaro/shared/providers/shared_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Chat Repository Provider - Using Dio for consistency
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatRepository(dio);
});

// Rooms State
class RoomsState {
  final List<Room> rooms;
  final bool isLoading;
  final String? error;

  RoomsState({this.rooms = const [], this.isLoading = false, this.error});

  RoomsState copyWith({List<Room>? rooms, bool? isLoading, String? error}) {
    return RoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Rooms Controller
class RoomsController extends StateNotifier<RoomsState> {
  final Ref _ref;
  bool _isDisposed = false;

  RoomsController(this._ref) : super(RoomsState());

  Future<void> loadRooms() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(chatRepositoryProvider);
      final roomsData = await repository.getUserRooms();
      final rooms = roomsData.map((r) => Room.fromJson(r)).toList();

      if (_isDisposed) return;
      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Map<String, dynamic>?> createRoom(String name) async {
    if (_isDisposed) return null;
    
    try {
      final repository = _ref.read(chatRepositoryProvider);
      final room = await repository.createRoom(name);
      await loadRooms();
      return room;
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinRoom(String roomCode) async {
    if (_isDisposed) return null;
    
    try {
      final repository = _ref.read(chatRepositoryProvider);
      final room = await repository.joinRoomByCode(roomCode);
      await loadRooms();
      return room;
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return null;
    }
  }

  Future<bool> deleteRoom(String roomId) async {
    if (_isDisposed) return false;
    
    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.deleteRoom(roomId);
      await loadRooms();
      return true;
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return false;
    }
  }

  Future<bool> leaveRoom(String roomId) async {
    if (_isDisposed) return false;
    
    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.leaveRoom(roomId);
      await loadRooms();
      return true;
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

// Rooms Controller Provider
final roomsControllerProvider =
    StateNotifierProvider<RoomsController, RoomsState>((ref) {
      return RoomsController(ref);
    });

// Room Details Provider (for single room)
final roomDetailsProvider = FutureProvider.family<Room, String>((
  ref,
  roomId,
) async {
  final repository = ref.watch(chatRepositoryProvider);
  final data = await repository.getRoomDetails(roomId);
  return Room.fromJson(data);
});