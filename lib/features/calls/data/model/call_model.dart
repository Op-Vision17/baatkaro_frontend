class CallModel {
  final String id;
  final String roomId;
  final String roomName;
  final String callType; // 'audio' or 'video'
  final CallUser caller;
  final List<CallParticipant> participants;
  final String status; // 'ringing', 'ongoing', 'ended'
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;

  CallModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.callType,
    required this.caller,
    required this.participants,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['_id'] ?? json['callId'] ?? '',
      roomId: json['roomId']?.toString() ?? '',
      roomName: json['roomName'] ?? 'Group Call',
      callType: json['callType'] ?? 'audio',
      caller: CallUser.fromJson(json['caller'] as Map<String, dynamic>),
      participants: (json['participants'] as List?)
              ?.map((p) => CallParticipant.fromJson(p))
              .toList() ??
          [],
      status: json['status'] ?? 'ringing',
      startTime: _parseStartTime(json['startTime'] ?? json['timestamp']),
      endTime:
          json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'],
    );
  }

  /// Build from FCM incoming_call payload (flat callerName/callerId/callerAvatar).
  static CallModel? fromFcmData(Map<String, dynamic> data) {
    final callerId = data['callerId']?.toString();
    final callerName = data['callerName']?.toString();
    if (callerId == null || callerName == null) return null;
    final roomId = data['roomId']?.toString() ?? '';
    final callId = data['callId']?.toString() ?? '';
    if (roomId.isEmpty || callId.isEmpty) return null;
    final startTime = _parseStartTime(data['timestamp']);
    return CallModel(
      id: callId,
      roomId: roomId,
      roomName: data['roomName']?.toString() ?? 'Group Call',
      callType: data['callType']?.toString() ?? 'audio',
      caller: CallUser(
        id: callerId,
        name: callerName,
        avatar: data['callerAvatar']?.toString(),
        email: null,
      ),
      participants: [],
      status: 'ringing',
      startTime: startTime,
    );
  }

  static DateTime _parseStartTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

class CallUser {
  final String id;
  final String name;
  final String? avatar;
  final String? email;

  CallUser({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
  });

  factory CallUser.fromJson(Map<String, dynamic> json) {
    return CallUser(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'] ?? json['profilePhoto'],
      email: json['email'],
    );
  }
}

class CallParticipant {
  final CallUser user;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String status; // 'joined', 'left', 'missed', 'rejected'

  CallParticipant({
    required this.user,
    required this.joinedAt,
    this.leftAt,
    required this.status,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      user: CallUser.fromJson(json['user'] as Map<String, dynamic>),
      joinedAt: DateTime.parse(json['joinedAt']),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
      status: json['callStatus'] ?? json['status'] ?? 'joined',
    );
  }
}