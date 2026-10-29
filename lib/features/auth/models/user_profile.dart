import 'user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.role = UserRole.customer,
    required this.createdAt,
  });

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    String? email,
    UserRole? role,
  }) {
    return UserProfile(
      id: json['id'] as String,
      email: email ?? (json['email'] as String? ?? ''),
      fullName: json['full_name'] as String? ?? 'User',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: role ?? UserRole.fromString(json['role'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    UserRole? role,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
