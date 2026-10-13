import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/app.dart';
import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/features/auth/application/placement_provider.dart';

import '../helpers/repository_fakes.dart';

Widget _app({
  FakeAuthRepository? auth,
  FakeConceptRepository? concepts,
  FakeProgressRepository? progress,
  FakeGamificationRepository? gamification,
}) {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(),
      ),
      placementCompletedProvider.overrideWith((ref) => Future.value(true)),
      conceptRepositoryProvider.overrideWithValue(
        concepts ?? FakeConceptRepository(),
      ),
      progressRepositoryProvider.overrideWithValue(
        progress ??
            FakeProgressRepository(
              states: [masteredState('K01'), learningState('K02')],
              answeredToday: 3,
            ),
      ),
      gamificationRepositoryProvider.overrideWithValue(
        gamification ?? FakeGamificationRepository(),
      ),
    ],
    retry: (_, __) => null,
  );
  return UncontrolledProviderScope(
    container: container,
    child: const AdaptiLearnApp(),
  );
}

Future<void> _pumpFrames(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('shell dan beranda siswa', () {
    testWidgets('beranda menampilkan data nyata', (tester) async {
      await tester.pumpWidget(_app());
      await _pumpFrames(tester);

      expect(find.text('Halo, Siswa Uji!'), findsOneWidget);
      expect(find.text('120 XP'), findsOneWidget);
      expect(find.text('4 hari'), findsOneWidget);
      expect(find.text('Operasi Aljabar'), findsOneWidget);
      expect(find.text('3 dari 5 soal hari ini'), findsOneWidget);
      expect(find.byKey(const Key('home-start-quiz')), findsOneWidget);
    });

    testWidgets('navigasi 4 tab berfungsi', (tester) async {
      await tester.pumpWidget(_app());
      await _pumpFrames(tester);

      await tester.tap(find.text('Peta'));
      await _pumpFrames(tester);
      expect(find.text('Legenda'), findsOneWidget);

      await tester.tap(find.text('Progres'));
      await _pumpFrames(tester);
      expect(find.text('Grafik progres segera hadir.'), findsOneWidget);

      await tester.tap(find.text('Profil'));
      await _pumpFrames(tester);
      expect(find.text('Siswa Uji'), findsWidgets);

      await tester.tap(find.text('Beranda'));
      await _pumpFrames(tester);
      expect(find.text('Halo, Siswa Uji!'), findsOneWidget);
    });

    testWidgets('dari beranda ke kuis cukup 1 ketukan', (tester) async {
      await tester.pumpWidget(_app());
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('home-start-quiz')));
      await _pumpFrames(tester);

      expect(find.text('Operasi Aljabar'), findsOneWidget);
      expect(find.text('Kuis segera hadir.'), findsOneWidget);
    });

    testWidgets('galat dimuat ulang lewat tombol coba lagi', (tester) async {
      await tester.pumpWidget(_app(
        progress: FakeProgressRepository()
          ..failure = const AppException('Gagal memuat data.'),
      ));
      await _pumpFrames(tester);

      expect(find.text('Gagal memuat data.'), findsWidgets);
      expect(find.text('Coba lagi'), findsWidgets);
    });

    testWidgets('kosong saat semua konsep dikuasai', (tester) async {
      await tester.pumpWidget(_app(
        progress: FakeProgressRepository(
          states: [
            masteredState('K01'),
            masteredState('K02'),
            masteredState('K03'),
          ],
        ),
      ));
      await _pumpFrames(tester);

      expect(
        find.text('Tidak ada konsep yang perlu dilanjutkan.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home-start-quiz')), findsNothing);
    });

    testWidgets('memuat menampilkan indikator', (tester) async {
      final concepts = FakeConceptRepository()
        ..gate = Completer<void>().future;
      await tester.pumpWidget(_app(concepts: concepts));
      await _pumpFrames(tester, 3);

      expect(find.text('Memuat rekomendasi…'), findsOneWidget);
    });
  });
}
