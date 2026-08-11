/// Response dari `GET /auth/profile`.
///
/// Field mengikuti persis apa yang dikirim backend, tanpa tambahan.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final bool isActive;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  bool get isPatient => role.toLowerCase() == 'patient';

  @override
  String toString() =>
      'UserProfile(id: $id, username: $username, role: $role, '
      'isActive: $isActive)';
}
