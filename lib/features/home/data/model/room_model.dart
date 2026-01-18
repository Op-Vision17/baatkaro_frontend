class Room {
  final String id;
  final String name;
  final String roomCode;
  final String? roomPhoto;
  final List<RoomMember> members;
  final RoomMember createdBy;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.roomCode,
    this.roomPhoto,
    required this.members,
    required this.createdBy,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      roomCode: json['roomCode'] ?? '',
      roomPhoto: json['roomPhoto'],
      members: (json['members'] as List?)
              ?.map((m) => RoomMember.fromJson(m))
              .toList() ??
          [],
      createdBy: RoomMember.fromJson(json['createdBy'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'roomCode': roomCode,
      'roomPhoto': roomPhoto,
      'members': members.map((m) => m.toJson()).toList(),
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RoomMember {
  final String id;
  final String name;
  final String email;
  final String? profilePhoto;

  RoomMember({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
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