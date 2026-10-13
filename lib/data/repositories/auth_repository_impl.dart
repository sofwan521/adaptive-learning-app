import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_service.dart';

/// Implementasi [AuthRepository] memakai Supabase Auth + tabel `profiles`.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  Future<UserProfile> _fetchProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        throw const AppException(
            'Profil tidak ditemukan. Silakan daftar ulang.');
      }
      return UserProfile.fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final safeRole = role == UserRole.admin ? UserRole.student : role;
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': safeRole.name},
      );
      final user = response.user;
      if (user == null) {
        throw const AppException(
            'Pendaftaran gagal. Silakan coba lagi.');
      }
      return await _fetchProfile(user.id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppException(
            'Surel atau kata sandi salah. Silakan coba lagi.');
      }
      return await _fetchProfile(user.id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<UserProfile?> currentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      try {
        return await _fetchProfile(user.id);
      } catch (_) {
        return null;
      }
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);
