/// Peran pengguna AdaptiLearn.
///
/// Logika murni — tanpa import Flutter.
enum UserRole {
  student,
  teacher,
  admin;

  /// Parse dari string (mis. dari Supabase). Default ke [student].
  static UserRole fromString(String? value) {
    switch (value) {
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  /// Label Bahasa Indonesia untuk UI.
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Siswa';
      case UserRole.teacher:
        return 'Guru';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
