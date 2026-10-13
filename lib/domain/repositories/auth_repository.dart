// Kontrak repository autentikasi (domain, tanpa import Flutter).
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Operasi autentikasi dan profil. Galat berupa [AppException].
abstract class AuthRepository {
  /// Daftar akun baru. [role] hanya student atau teacher
  /// (selain itu dipaksa menjadi student oleh backend).
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  /// Masuk dengan surel dan kata sandi.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  });

  /// Keluar dari sesi saat ini.
  Future<void> signOut();

  /// Profil pengguna aktif, atau null bila belum masuk.
  Future<UserProfile?> currentProfile();

  /// Profil aktif yang berubah mengikuti status auth.
  Stream<UserProfile?> authStateChanges();
}
