class User {
  final String id;
  final String username;
  final String email;
  final String password; // Note: In a real app, you should never store plain text passwords
  final String? profileImageUrl;
  final String? bio;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.profileImageUrl,
    this.bio,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? profileImageUrl,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
    );
  }
}
