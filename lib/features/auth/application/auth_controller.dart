import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/auth_repository.dart';

/// Status sesi autentikasi.
enum AuthStatus {
  /// Memeriksa sesi tersimpan.
  initial,

  /// Operasi auth sedang berjalan.
  loading,

  /// Sudah masuk.
  authenticated,

  /// Belum masuk.
  unauthenticated,
}

/// State autentikasi: loading, galat, dan profil terautentikasi.
class AuthState extends Equatable {
  final AuthStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.profile,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && profile != null;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

/// Pengendali autentikasi (Riverpod Notifier).
///
/// Bekorelasi dengan [AuthRepository] dan memulihkan sesi saat aplikasi
/// dibuka. Bila backend belum dikonfigurasi, pengguna dianggap belum
/// masuk agar aplikasi tetap berjalan luring.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<UserProfile?>? _subscription;

  @override
  AuthState build() {
    ref.onDispose(() => _subscription?.cancel());
    Future.microtask(_restore);
    return const AuthState();
  }

  AuthRepository? _repositoryOrNull() {
    try {
      return ref.watch(authRepositoryProvider);
    } catch (_) {
      return null;
    }
  }

  Future<void> _restore() async {
    state = state.copyWith(status: AuthStatus.loading);
    final repository = _repositoryOrNull();
    if (repository == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    await _subscription?.cancel();
    _subscription = repository.authStateChanges().listen(
          (profile) => state = profile == null
              ? state.copyWith(
                  status: AuthStatus.unauthenticated, clearProfile: true)
              : AuthState(
                  status: AuthStatus.authenticated, profile: profile),
        );
    try {
      final profile = await repository.currentProfile();
      // Abaikan bila stream sudah memperbarui state lebih dulu.
      if (state.status == AuthStatus.loading) {
        state = profile == null
            ? state.copyWith(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, profile: profile);
      }
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    }
  }

  /// Masuk dengan surel dan kata sandi.
  Future<bool> signIn({required String email, required String password}) async {
    final repository = _repositoryOrNull();
    if (repository == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'Backend belum dikonfigurasi. Jalankan dengan --dart-define.',
      );
      return false;
    }
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final profile =
          await repository.signIn(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    }
  }

  /// Daftar akun siswa atau guru.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final repository = _repositoryOrNull();
    if (repository == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'Backend belum dikonfigurasi. Jalankan dengan --dart-define.',
      );
      return false;
    }
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final profile = await repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    }
  }

  /// Keluar dari sesi saat ini.
  Future<void> signOut() async {
    final repository = _repositoryOrNull();
    if (repository != null) {
      try {
        await repository.signOut();
      } on AppException catch (e) {
        state = state.copyWith(errorMessage: e.message);
      }
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Hapus pesan galat setelah ditampilkan.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
