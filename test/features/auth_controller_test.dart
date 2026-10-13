import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/domain/models/user_profile.dart';
import 'package:adaptive_learning_app/domain/models/user_role.dart';
import 'package:adaptive_learning_app/domain/repositories/auth_repository.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/features/auth/application/auth_controller.dart';

class FakeAuthRepository implements AuthRepository {
  UserProfile? profile;
  UserRole nextRole = UserRole.student;
  AppException? failure;
  final _events = StreamController<UserProfile?>.broadcast();

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    if (failure != null) throw failure!;
    profile = UserProfile(id: 'baru-1', fullName: fullName, role: role);
    _events.add(profile);
    return profile!;
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    profile = UserProfile(id: 'u-1', fullName: 'Siswa Uji', role: nextRole);
    _events.add(profile);
    return profile!;
  }

  @override
  Future<void> signOut() async {
    profile = null;
    _events.add(null);
  }

  @override
  Future<UserProfile?> currentProfile() async => profile;

  @override
  Stream<UserProfile?> authStateChanges() => _events.stream;
}

ProviderContainer _container(FakeAuthRepository fake) {
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
  );
}

Future<void> _settleReady(ProviderContainer container) async {
  // Picu build (menjadwalkan pemulihan sesi) lalu beri waktu selesai.
  container.read(authControllerProvider);
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('AuthController', () {
    test('mulai belum masuk bila tak ada sesi', () async {
      final container = _container(FakeAuthRepository());
      addTearDown(container.dispose);

      await _settleReady(container);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.profile, isNull);
    });

    test('masuk berhasil terautentikasi', () async {
      final container = _container(FakeAuthRepository());
      addTearDown(container.dispose);
      await _settleReady(container);

      final notifier = container.read(authControllerProvider.notifier);
      final pending = notifier.signIn(
        email: 'siswa@contoh.id',
        password: 'sandi123',
      );
      expect(container.read(authControllerProvider).isLoading, isTrue);
      expect(await pending, isTrue);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.profile?.role, UserRole.student);
      expect(state.errorMessage, isNull);
    });

    test('masuk gagal menyimpan pesan galat ramah', () async {
      final fake = FakeAuthRepository()
        ..failure = const AppException('Surel atau kata sandi salah.');
      final container = _container(fake);
      addTearDown(container.dispose);
      await _settleReady(container);

      final ok = await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'siswa@contoh.id', password: 'salah1234');

      expect(ok, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Surel atau kata sandi salah.');
    });

    test('daftar meneruskan peran guru', () async {
      final container = _container(FakeAuthRepository());
      addTearDown(container.dispose);
      await _settleReady(container);

      final ok = await container
          .read(authControllerProvider.notifier)
          .signUp(
            email: 'guru@contoh.id',
            password: 'sandi123',
            fullName: 'Guru Uji',
            role: UserRole.teacher,
          );

      expect(ok, isTrue);
      expect(
        container.read(authControllerProvider).profile?.role,
        UserRole.teacher,
      );
    });

    test('keluar kembali belum masuk', () async {
      final container = _container(FakeAuthRepository());
      addTearDown(container.dispose);
      await _settleReady(container);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signIn(email: 'siswa@contoh.id', password: 'sandi123');
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      await notifier.signOut();
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.profile, isNull);
    });

    test('clearError menghapus pesan', () async {
      final fake = FakeAuthRepository()
        ..failure = const AppException('Tidak ada koneksi internet.');
      final container = _container(fake);
      addTearDown(container.dispose);
      await _settleReady(container);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'siswa@contoh.id', password: 'sandi123');
      expect(
        container.read(authControllerProvider).errorMessage,
        isNotNull,
      );
      container.read(authControllerProvider.notifier).clearError();
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });
  });
}
