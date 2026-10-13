import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/response_history.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_progress_screen.dart';

import '../helpers/repository_fakes.dart';

List<ResponseHistoryEntry> _responses(DateTime now) => [
      ResponseHistoryEntry(
        sessionId: 's1',
        isCorrect: true,
        thetaAfter: 0.1,
        answeredAt: now.subtract(const Duration(hours: 5)),
      ),
      ResponseHistoryEntry(
        sessionId: 's1',
        isCorrect: false,
        thetaAfter: 0.0,
        answeredAt: now.subtract(const Duration(hours: 4)),
      ),
      ResponseHistoryEntry(
        sessionId: 's2',
        isCorrect: true,
        thetaAfter: 0.5,
        answeredAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

List<QuizSession> _sessions(DateTime now) => [
      QuizSession(
        id: 's1',
        studentId: 'siswa-1',
        conceptId: 'K01',
        status: QuizSessionStatus.finished,
        finalTheta: 0.0,
        startedAt: now.subtract(const Duration(hours: 5)),
        finishedAt: now.subtract(const Duration(hours: 4)),
      ),
      QuizSession(
        id: 's2',
        studentId: 'siswa-1',
        conceptId: 'K02',
        status: QuizSessionStatus.finished,
        finalTheta: 0.5,
        startedAt: now.subtract(const Duration(hours: 1)),
        finishedAt: now,
      ),
    ];

Future<void> _pumpScreen(
  WidgetTester tester, {
  FakeProgressRepository? progress,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      conceptRepositoryProvider.overrideWithValue(FakeConceptRepository()),
      progressRepositoryProvider.overrideWithValue(
        progress ?? FakeProgressRepository(),
      ),
    ],
    retry: (_, __) => null,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: StudentProgressScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('StudentProgressScreen berisi', () {
    testWidgets('menampilkan data nyata setelah beberapa kuis',
        (tester) async {
      final now = DateTime.now();
      await _pumpScreen(
        tester,
        progress: FakeProgressRepository(
          states: [masteredState('K01'), learningState('K02')],
          sessions: _sessions(now),
          responses: _responses(now),
        ),
      );

      // Ringkasan angka.
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Total soal'), findsOneWidget);
      // Grafik theta.
      expect(find.text('Perkembangan Theta'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      // Bar per konsep.
      expect(find.text('Penguasaan per Konsep'), findsOneWidget);
      expect(find.text('Bilangan Bulat'), findsWidgets);
      // Riwayat kuis dengan skor tiap sesi.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      expect(find.text('Riwayat Kuis'), findsOneWidget);
      expect(find.textContaining('1/2 benar'), findsOneWidget);
      expect(find.textContaining('1/1 benar'), findsOneWidget);
    });

    testWidgets('tarik untuk menyegarkan tidak merusak tampilan',
        (tester) async {
      final now = DateTime.now();
      await _pumpScreen(
        tester,
        progress: FakeProgressRepository(
          states: [masteredState('K01')],
          sessions: _sessions(now),
          responses: _responses(now),
        ),
      );

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ringkasan'), findsOneWidget);
    });
  });

  group('StudentProgressScreen kosong', () {
    testWidgets('siswa baru melihat ajakan mulai belajar', (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Belum ada progres'), findsOneWidget);
      expect(find.text('Mulai Belajar'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });
  });
}
