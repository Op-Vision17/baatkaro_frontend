// features/chats/data/models/message_model.dart

class Message {
  final String id;
  final String text;
  final String? imageUrl;
  final String? voiceUrl;
  final int? voiceDuration;
  final MessageSender sender;
  final DateTime createdAt;
  final bool isUploading;
  final double uploadProgress;
  final String? localFilePath;

  // ✅ DELETE FUNCTIONALITY
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  // ✅ NEW: Message type and call data
  final MessageType messageType;
  final CallData? callData;

  Message({
    required this.id,
    required this.text,
    this.imageUrl,
    this.voiceUrl,
    this.voiceDuration,
    required this.sender,
    required this.createdAt,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.localFilePath,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.messageType = MessageType.text,
    this.callData,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVoice => voiceUrl != null && voiceUrl!.isNotEmpty;
  bool get canBeDeleted => !isDeleted && !isUploading;
  bool get isCallMessage => messageType == MessageType.call;

  Message copyWith({
    String? id,
    String? text,
    String? imageUrl,
    String? voiceUrl,
    int? voiceDuration,
    MessageSender? sender,
    DateTime? createdAt,
    bool? isUploading,
    double? uploadProgress,
    String? localFilePath,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    MessageType? messageType,
    CallData? callData,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      localFilePath: localFilePath ?? this.localFilePath,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      messageType: messageType ?? this.messageType,
      callData: callData ?? this.callData,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Determine message type
    final typeStr = json['messageType']?.toString() ?? 'text';
    MessageType messageType;

    // Handle message type conversion
    if (typeStr == 'call') {
      messageType = MessageType.call;
    } else if (typeStr == 'image') {
      messageType = MessageType.image;
    } else if (typeStr == 'voice') {
      messageType = MessageType.voice;
    } else {
      messageType = MessageType.text;
    }

    return Message(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      voiceUrl: json['voiceUrl']?.toString(),
      voiceDuration: json['voiceDuration'] as int?,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      isUploading: false,
      uploadProgress: 1.0,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'].toString())
          : null,
      deletedBy: json['deletedBy']?.toString(),
      messageType: messageType,
      callData: json['callData'] != null
          ? CallData.fromJson(json['callData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'sender': sender.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'messageType': messageType.name,
      'callData': callData?.toJson(),
    };
  }
}

// ✅ NEW: Message Type Enum
enum MessageType { text, image, voice, call }

// ✅ NEW: Call Data Model
class CallData {
  final String callId;
  final String callType; // 'audio' or 'video'
  final String status; // 'started', 'ongoing', 'ended', 'missed'
  final String initiatorId;
  final String initiatorName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in seconds
  final int participantCount;
  final bool wasAnswered;

  CallData({
    required this.callId,
    required this.callType,
    required this.status,
    required this.initiatorId,
    required this.initiatorName,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.participantCount,
    required this.wasAnswered,
  });

  bool get isOngoing => status == 'ongoing';
  bool get isEnded => status == 'ended';
  bool get isMissed => status == 'missed';

  /// True when the call can still be joined (ongoing, ringing, or just started).
  bool get isJoinable =>
      status == 'ongoing' || status == 'ringing' || status == 'started';

  String get durationText {
    if (duration == null) return '';

    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String _idFromJson(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final v = value['\$oid'] ?? value['oid'] ?? value['id'];
      if (v != null) return v.toString();
    }
    return value.toString();
  }

  factory CallData.fromJson(Map<String, dynamic> json) {
    return CallData(
      callId: _idFromJson(json['callId']),
      callType: json['callType']?.toString() ?? 'audio',
      status: json['status']?.toString() ?? 'started',
      initiatorId: _idFromJson(json['initiatorId']),
      initiatorName: json['initiatorName']?.toString() ?? '',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'].toString())
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'].toString())
          : null,
      duration: json['duration'] as int?,
      participantCount: json['participantCount'] as int? ?? 0,
      wasAnswered: json['wasAnswered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callType': callType,
      'status': status,
      'initiatorId': initiatorId,
      'initiatorName': initiatorName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'participantCount': participantCount,
      'wasAnswered': wasAnswered,
    };
  }
}

class MessageSender {
  final String id;
  final String name;
  final String? email;
  final String? profilePhoto;

  MessageSender({
    required this.id,
    required this.name,
    this.email,
    this.profilePhoto,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'],
      profilePhoto: json['profilePhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
    };
  }
}

// ✅ Typing User Model (unchanged)
class TypingUser {
  final String userId;
  final String name;
  final String? profilePhoto;

  TypingUser({required this.userId, required this.name, this.profilePhoto});

  factory TypingUser.fromJson(Map<String, dynamic> json) {
    return TypingUser(
      userId: json['userId']?.toString() ?? '',
      name: json['name'] ?? 'Someone',
      profilePhoto: json['profilePhoto'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
