import 'package:cloud_firestore/cloud_firestore.dart';

/// A user's chosen profile picture. Deliberately not a "gender" field: it's
/// a visual choice stored as an avatar id, not a demographic data point.
enum AvatarOption { male, femaleHijab }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final AvatarOption? avatar;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    DateTime? createdAt,
    this.avatar,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'createdAt': Timestamp.fromDate(createdAt),
        'avatar': avatar?.name,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        avatar: _parseAvatar(map['avatar']),
      );

  AppUser copyWith({String? name, AvatarOption? avatar}) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email,
        createdAt: createdAt,
        avatar: avatar ?? this.avatar,
      );

  static AvatarOption? _parseAvatar(dynamic value) {
    for (final option in AvatarOption.values) {
      if (option.name == value) return option;
    }
    return null;
  }
}
