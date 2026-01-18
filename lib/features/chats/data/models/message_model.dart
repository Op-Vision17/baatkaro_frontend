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

  // ✅ NEW: Delete functionality fields
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

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
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVoice => voiceUrl != null && voiceUrl!.isNotEmpty;
  bool get canBeDeleted => !isDeleted && !isUploading;

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
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
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

// ✅ NEW: Typing User Model
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
