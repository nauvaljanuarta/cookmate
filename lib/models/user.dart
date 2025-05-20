import 'package:pocketbase/pocketbase.dart';

class User {
  final String id;
  final String email;
  final String username;
  final String bio;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.bio,
    this.profileImage,
  });

  factory User.fromRecord(RecordModel record) {
    return User(
      id: record.id,
      email: record.getStringValue('email', ''),
      username: record.getStringValue('username', ''),
      bio: record.getStringValue('bio', ''),
      profileImage: record.getStringValue('profileImage'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'bio': bio,
        'profileImage': profileImage,
      };
}