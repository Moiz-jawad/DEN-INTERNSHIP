class UserProfile {
  final String id;
  final String email;
  final String username;
  final String avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String,
      username: data['username'] as String? ?? '',
      avatarUrl: data['avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }
}
