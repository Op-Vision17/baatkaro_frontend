class User {
  final String id;
  final String? name;
  final String email;
  final String? profilePhoto;
  final String? accessToken;
  final String? refreshToken;
  final bool needsOnboarding;

  User({
    required this.id,
    this.name,
    required this.email,
    this.profilePhoto,
    this.accessToken,
    this.refreshToken,
    this.needsOnboarding = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      profilePhoto: json['profilePhoto'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      needsOnboarding: json['needsOnboarding'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'needsOnboarding': needsOnboarding,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhoto,
    String? accessToken,
    String? refreshToken,
    bool? needsOnboarding,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }
}