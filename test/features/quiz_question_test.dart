import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/widgets/widgets.dart';
import 'package:adaptive_learning_app/data/datasources/quiz_resume_store.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/item_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/repositories/item_repository.dart';
import 'package:adaptive_learning_app/features/auth/application/auth_controller.dart';
import 'package:adaptive_learning_app/features/quiz/presentation/quiz_screen.dart';

import '../helpers/repository_fakes.dart';

class _QuizItemRepository implements ItemRepository {
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

class _FixedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        profile: testStudent,
      );
}

class _MemoryResumeStore implements QuizResumeStore {
  QuizResumeSnapshot? snapshot;

  @override
  Future<QuizResumeSnapshot?> load() async => snapshot;

  @override
  Future<void> save(QuizResumeSnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

Future<void> _pumpQuiz(WidgetTester tester) async {
  final container = ProviderContainer.test(
    overrides: [
      authControllerProvider.overrideWith(() => _FixedAuthController()),
      itemRepositoryProvider.overrideWithValue(_QuizItemRepository()),
      progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
      gamificationRepositoryProvider.overrideWithValue(
        FakeGamificationRepository(),
      ),
      quizResumeStoreProvider.overrideWithValue(_MemoryResumeStore()),
      conceptRepositoryProvider.overrideWithValue(FakeConceptRepository()),
    ],
    retry: (_, __) => null,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: QuizScreen(conceptId: 'K02'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

AppButton _jawabButton(WidgetTester tester) =>
    tester.widget<AppButton>(find.byKey(const Key('quiz-answer')));

void main() {
  group('Kartu soal kuis', () {
    testWidgets('menampilkan soal, opsi, dan progres', (tester) async {
      await _pumpQuiz(tester);

      expect(find.textContaining('Soal K02 nomor'), findsOneWidget);
      expect(find.text('Soal 1 dari 4'), findsOneWidget);
      expect(find.byKey(const Key('quiz-option-0')), findsOneWidget);
      expect(find.byKey(const Key('quiz-option-3')), findsOneWidget);
      expect(find.text('A'), findsWidgets);
      expect(find.byKey(const Key('quiz-answer')), findsOneWidget);
    });

    testWidgets('tombol Jawab nonaktif sebelum memilih', (tester) async {
      await _pumpQuiz(tester);

      expect(_jawabButton(tester).onPressed, isNull);

      // Mengetuk tanpa pilihan tidak memajukan ke umpan balik.
      await tester.tap(find.byKey(const Key('quiz-answer')));
      await tester.pump();

      expect(find.byKey(const Key('quiz-answer')), findsOneWidget);
      expect(find.text('Pembahasan'), findsNothing);
    });

    testWidgets('memilih opsi mengaktifkan Jawab', (tester) async {
      await _pumpQuiz(tester);

      await tester.tap(find.byKey(const Key('quiz-option-1')));
      await tester.pump();

      expect(_jawabButton(tester).onPressed, isNotNull);
    });

    testWidgets('menjawab menampilkan umpan balik dan pembahasan', (
      tester,
    ) async {
      await _pumpQuiz(tester);

      await tester.tap(find.byKey(const Key('quiz-option-0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('quiz-answer')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Pembahasan'), findsOneWidget);
      expect(find.textContaining('Pembahasan K02-'), findsOneWidget);
      expect(find.byKey(const Key('quiz-next')), findsOneWidget);
      // Salah satu banner umpan balik muncul.
      final benar = find.text('Benar! Kerja bagus.');
      final salah = find.text('Kurang tepat. Pelajari pembahasannya.');
      expect(
        benar.evaluate().isNotEmpty || salah.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
