import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/user_profile.dart';
import 'package:adaptive_learning_app/domain/models/user_role.dart';
import 'package:adaptive_learning_app/domain/repositories/auth_repository.dart';
import 'package:adaptive_learning_app/features/auth/presentation/login_screen.dart';

import '../helpers/repository_fakes.dart';

/// Fake auth dengan pencatatan pemanggilan dan mode gagal.
class _SpyAuthRepository implements AuthRepository {
  int signInCalls = 0;
  String? lastEmail;
  AppException? failure;

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    if (failure != null) throw failure!;
    return testStudent;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async =>
      testStudent;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfile?> currentProfile() async => null;

  @override
  Stream<UserProfile?> authStateChanges() => const Stream.empty();
}

Future<void> _pumpLogin(
  WidgetTester tester,
  _SpyAuthRepository fake,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pump();
  // Biarkan pemulihan sesi awal selesai.
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    '  siswa@contoh.id  ',
  );
  await tester.enterText(
    find.byKey(const Key('login-password')),
    'sandi123',
  );
  await tester.pump();
}

void main() {
  group('LoginScreen', () {
    testWidgets('menampilkan formulir masuk', (tester) async {
      await _pumpLogin(tester, _SpyAuthRepository());

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
      expect(find.text('Masuk'), findsWidgets);
    });

    testWidgets('form kosong menampilkan galat validasi', (tester) async {
      final fake = _SpyAuthRepository();
      await _pumpLogin(tester, fake);

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();

      expect(find.text('Surel tidak boleh kosong.'), findsOneWidget);
      expect(find.text('Kata sandi tidak boleh kosong.'), findsOneWidget);
      expect(fake.signInCalls, 0);
    });

    testWidgets('surel dan sandi tak valid menampilkan galat', (
      tester,
    ) async {
      final fake = _SpyAuthRepository();
      await _pumpLogin(tester, fake);

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'bukan-surel',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'pendek',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();

      expect(find.text('Format surel tidak valid.'), findsOneWidget);
      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
      expect(fake.signInCalls, 0);
    });

    testWidgets('kredensial salah menampilkan SnackBar galat', (
      tester,
    ) async {
      final fake = _SpyAuthRepository()
        ..failure = const AppException('Surel atau kata sandi salah.');
      await _pumpLogin(tester, fake);

      await _fillValidForm(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.signInCalls, 1);
      expect(
        find.text('Surel atau kata sandi salah.'),
        findsOneWidget,
      );
    });

    testWidgets('masuk berhasil memakai surel terpotong spasi', (
      tester,
    ) async {
      final fake = _SpyAuthRepository();
      await _pumpLogin(tester, fake);

      await _fillValidForm(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.signInCalls, 1);
      expect(fake.lastEmail, 'siswa@contoh.id');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('ikon mata mengubah visibilitas sandi', (tester) async {
      await _pumpLogin(tester, _SpyAuthRepository());

      bool obscured() => tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('login-password')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText;

      await tester.enterText(
        find.byKey(const Key('login-password')),
        'sandi123',
      );
      await tester.pump();
      expect(obscured(), isTrue);

      await tester.tap(find.byTooltip('Lihat sandi'));
      await tester.pump();

      expect(obscured(), isFalse);
      expect(find.byTooltip('Sembunyikan sandi'), findsOneWidget);
    });
  });
}
