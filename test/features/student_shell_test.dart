import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adaptive_learning_app/app.dart';
import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/item_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/repositories/item_repository.dart';
import 'package:adaptive_learning_app/features/auth/application/placement_provider.dart';

import '../helpers/repository_fakes.dart';

/// Bank kecil K02 untuk menembus layar kuis dari beranda.
class _ShellItemRepository implements ItemRepository {
  @override
  Future<List<Item>> fetchItems(String conceptId) async {
    return [
      for (var i = 0; i < 4; i++)
        Item(
          id: 'k02-q${i + 1}',
          conceptId: 'K02',
          question: 'Soal K02 nomor ${i + 1}',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          a: 1.0,
          b: -1.0 + i,
          explanation: 'Pembahasan K02-${i + 1}',
        ),
    ];
  }

  @override
  Future<List<Item>> fetchPlacementItems({int limit = 20}) async => [];
}

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
      itemRepositoryProvider.overrideWithValue(_ShellItemRepository()),
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
  setUpAll(() {
    // shared_preferences butuh nilai awal di uji widget agar
    // penyimpanan resume kuis tidak menggantung.
    SharedPreferences.setMockInitialValues({});
  });

  group('shell dan beranda siswa', () {
    testWidgets('beranda menampilkan data nyata', (tester) async {
      await tester.pumpWidget(_app());
      await _pumpFrames(tester);

      expect(find.text('Halo, Siswa Uji!'), findsOneWidget);
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
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('Perkembangan Skor'), findsOneWidget);

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
      expect(find.textContaining('Soal K02 nomor'), findsOneWidget);
      expect(find.text('Jawab'), findsOneWidget);
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
