import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/app.dart';
import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/user_profile.dart';
import 'package:adaptive_learning_app/domain/models/user_role.dart';
import 'package:adaptive_learning_app/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  UserProfile? profile;
  UserRole nextRole = UserRole.student;
  String nextName = 'Siswa Uji';
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
    profile = UserProfile(id: 'u-1', fullName: nextName, role: nextRole);
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

Widget _app(FakeAuthRepository fake) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: const AdaptiLearnApp(),
  );
}

Future<void> _pumpFrames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _loginAs(
  WidgetTester tester, {
  String email = 'siswa@contoh.id',
  String password = 'sandi123',
}) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.tap(find.byKey(const Key('login-submit')));
  await _pumpFrames(tester, 15);
}

void main() {
  group('alur auth dan redirect peran', () {
    testWidgets('belum masuk diarahkan ke login', (tester) async {
      await tester.pumpWidget(_app(FakeAuthRepository()));
      await _pumpFrames(tester);

      expect(
        find.text('Lanjutkan belajarmu di AdaptiLearn'),
        findsOneWidget,
      );
    });

    testWidgets('form login kosong menampilkan galat validasi', (tester) async {
      await tester.pumpWidget(_app(FakeAuthRepository()));
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();

      expect(find.text('Surel tidak boleh kosong.'), findsOneWidget);
      expect(
        find.text('Lanjutkan belajarmu di AdaptiLearn'),
        findsOneWidget,
      );
    });

    testWidgets('siswa masuk diarahkan ke placement', (tester) async {
      await tester.pumpWidget(_app(FakeAuthRepository()));
      await _pumpFrames(tester);

      await _loginAs(tester);

      expect(find.text('Tes Penempatan'), findsOneWidget);
    });

    testWidgets('guru masuk diarahkan ke kelas', (tester) async {
      final fake = FakeAuthRepository()
        ..nextRole = UserRole.teacher
        ..nextName = 'Guru Uji';
      await tester.pumpWidget(_app(fake));
      await _pumpFrames(tester);

      await _loginAs(tester, email: 'guru@contoh.id');

      expect(find.text('Kelas Saya'), findsOneWidget);
    });

    testWidgets('gagal masuk menampilkan SnackBar ramah', (tester) async {
      final fake = FakeAuthRepository()
        ..failure = const AppException('Surel atau kata sandi salah.');
      await tester.pumpWidget(_app(fake));
      await _pumpFrames(tester);

      await _loginAs(tester);

      expect(find.text('Surel atau kata sandi salah.'), findsOneWidget);
      expect(
        find.text('Lanjutkan belajarmu di AdaptiLearn'),
        findsOneWidget,
      );
    });

    testWidgets('daftar sebagai guru lalu keluar kembali ke login',
        (tester) async {
      await tester.pumpWidget(_app(FakeAuthRepository()));
      await _pumpFrames(tester);

      await tester.tap(find.text('Daftar'));
      await _pumpFrames(tester);
      expect(find.text('Buat akun AdaptiLearn'), findsOneWidget);

      await tester.tap(find.text('Guru'));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('register-name')), 'Guru Uji');
      await tester.enterText(
          find.byKey(const Key('register-email')), 'guru@contoh.id');
      await tester.enterText(
          find.byKey(const Key('register-password')), 'sandi123');
      await tester.enterText(
          find.byKey(const Key('register-confirm')), 'sandi123');
      await tester.ensureVisible(
        find.byKey(const Key('register-submit')),
      );
      await _pumpFrames(tester, 5);
      await tester.tap(find.byKey(const Key('register-submit')));
      await _pumpFrames(tester, 15);

      expect(find.text('Kelas Saya'), findsOneWidget);

      await tester.tap(find.text('Keluar'));
      await _pumpFrames(tester);
      expect(
        find.text('Lanjutkan belajarmu di AdaptiLearn'),
        findsOneWidget,
      );
    });
  });
}
