import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Profil pengguna aplikasi (cermin tabel `profiles`).
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final UserRole role;

  const UserProfile({
    required this.id,
    this.fullName = '',
    this.role = UserRole.student,
  });

  UserProfile copyWith({String? id, String? fullName, UserRole? role}) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  /// Baris Supabase (`profiles`) ke profil domain.
  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String? ?? '',
      role: UserRole.fromString(row['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'role': role.name,
    };
  }

  @override
  List<Object?> get props => [id, fullName, role];
}
