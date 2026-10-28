import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/irt/score_scale.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/response_history.dart';
import 'package:adaptive_learning_app/features/progress/application/progress_dashboard.dart';

import '../helpers/repository_fakes.dart';

Map<String, ({String code, String name})> _concepts() => const {
      'K01': (code: 'K01', name: 'Bilangan Bulat'),
      'K02': (code: 'K02', name: 'Operasi Aljabar'),
      'K03': (code: 'K03', name: 'Persamaan Linear'),
    };

List<String> _order() => const ['K01', 'K02', 'K03'];

Map<String, ConceptStatus> _statuses() => const {
      'K01': ConceptStatus.mastered,
      'K02': ConceptStatus.learning,
      'K03': ConceptStatus.locked,
    };

ResponseHistoryEntry _response({
  required String sessionId,
  required bool correct,
  required double theta,
  required DateTime at,
}) {
  return ResponseHistoryEntry(
    sessionId: sessionId,
    isCorrect: correct,
    thetaAfter: theta,
    answeredAt: at,
  );
}

QuizSession _session({
  required String id,
  String? conceptId,
  QuizSessionStatus status = QuizSessionStatus.finished,
  double? theta,
  DateTime? startedAt,
}) {
  return QuizSession(
    id: id,
    studentId: 'siswa-1',
    conceptId: conceptId,
    status: status,
    finalTheta: theta,
    startedAt: startedAt,
    finishedAt: startedAt,
  );
}

void main() {
  final now = DateTime(2026, 10, 13, 12);

  group('buildProgressDashboard kosong', () {
    test('siswa baru tanpa data menandai kosong', () {
      final dashboard = buildProgressDashboard(
        concepts: _concepts(),
        orderedIds: _order(),
        statesById: const {},
        statuses: const {},
        sessions: const [],
        responses: const [],
        now: now,
      );

      expect(dashboard.isEmpty, isTrue);
      expect(dashboard.scorePoints, isEmpty);
      expect(dashboard.accuracy7d, isNull);
      expect(dashboard.totalAnswered, 0);
      expect(dashboard.bars, hasLength(3));
    });
  });

  group('buildProgressDashboard berisi', () {
    List<ResponseHistoryEntry> responses() => [
          _response(
            sessionId: 's1',
            correct: true,
            theta: -0.4,
            at: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          _response(
            sessionId: 's1',
            correct: false,
            theta: -0.2,
            at: now.subtract(const Duration(days: 1, hours: 1)),
          ),
          _response(
            sessionId: 's2',
            correct: true,
            theta: 0.1,
            at: now.subtract(const Duration(hours: 3)),
          ),
          _response(
            sessionId: 's2',
            correct: true,
            theta: 0.4,
            at: now.subtract(const Duration(hours: 2)),
          ),
          _response(
            sessionId: 's2',
            correct: true,
            theta: 0.6,
            at: now.subtract(const Duration(hours: 1)),
          ),
          // Di luar jendela 7 hari: ikut total, bukan akurasi.
          _response(
            sessionId: 's0',
            correct: false,
            theta: -1.0,
            at: now.subtract(const Duration(days: 10)),
          ),
        ];

    ProgressDashboard build() {
      return buildProgressDashboard(
        concepts: _concepts(),
        orderedIds: _order(),
        statesById: {
          'K01': masteredState('K01'),
          'K02': learningState('K02'),
        },
        statuses: _statuses(),
        sessions: [
          _session(
            id: 's1',
            conceptId: 'K01',
            theta: -0.2,
            startedAt: now.subtract(const Duration(days: 1)),
          ),
          _session(
            id: 's2',
            conceptId: 'K02',
            theta: 0.6,
            startedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        responses: responses(),
        now: now,
      );
    }

    test('titik skor per respons menaik waktu', () {
      final dashboard = build();

      expect(dashboard.isEmpty, isFalse);
      expect(dashboard.scoreSource, 'respons');
      expect(dashboard.scorePoints, hasLength(6));
      for (var i = 1; i < dashboard.scorePoints.length; i++) {
        expect(
          dashboard.scorePoints[i].time
              .isAfter(dashboard.scorePoints[i - 1].time),
          isTrue,
        );
      }
      expect(
        dashboard.scorePoints.last.percent,
        closeTo(thetaToPercent(0.6), 1e-9),
      );
    });

    test('titik dibatasi 30 terakhir', () {
      final many = [
        for (var i = 0; i < 40; i++)
          _response(
            sessionId: 's$i',
            correct: true,
            theta: -2.0 + i * 0.1,
            at: now.subtract(Duration(hours: 40 - i)),
          ),
      ];
      final dashboard = buildProgressDashboard(
        concepts: _concepts(),
        orderedIds: _order(),
        statesById: const {},
        statuses: const {},
        sessions: const [],
        responses: many,
        now: now,
      );

      expect(dashboard.scorePoints, hasLength(30));
      expect(
        dashboard.scorePoints.first.percent,
        closeTo(thetaToPercent(-1.0), 1e-9),
      );
      expect(
        dashboard.scorePoints.last.percent,
        closeTo(thetaToPercent(1.9), 1e-9),
      );
    });

    test('fallback ke skor per sesi bila respons tanpa theta', () {
      final dashboard = buildProgressDashboard(
        concepts: _concepts(),
        orderedIds: _order(),
        statesById: const {},
        statuses: const {},
        sessions: [
          _session(
            id: 's1',
            conceptId: 'K01',
            theta: 0.3,
            startedAt: now.subtract(const Duration(days: 2)),
          ),
          _session(
            id: 's2',
            conceptId: null,
            theta: 0.8,
            startedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        responses: [
          ResponseHistoryEntry(
            sessionId: 's1',
            isCorrect: true,
            answeredAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        now: now,
      );

      expect(dashboard.scoreSource, 'sesi');
      expect(
        dashboard.scorePoints.map((p) => p.percent),
        [thetaToPercent(0.3), thetaToPercent(0.8)],
      );
    });

    test('ringkasan: dikuasai, akurasi 7 hari, total', () {
      final dashboard = build();

      expect(dashboard.masteredCount, 1);
      expect(dashboard.totalConcepts, 3);
      // 4 benar dari 5 dalam 7 hari.
      expect(dashboard.accuracy7d, closeTo(0.8, 1e-9));
      expect(dashboard.totalAnswered, 6);
    });

    test('bar per konsep terurut dengan persen dan status', () {
      final dashboard = build();

      expect(
        dashboard.bars.map((b) => b.conceptId),
        ['K01', 'K02', 'K03'],
      );
      expect(dashboard.bars.first.status, ConceptStatus.mastered);
      expect(
        dashboard.bars.first.percent,
        closeTo(thetaToPercent(masteredState('K01').thetaC), 1e-9),
      );
      expect(dashboard.bars.last.percent, 0.0);
    });

    test('riwayat menggabung skor tiap sesi terbaru dulu', () {
      final dashboard = build();

      expect(dashboard.history, hasLength(2));
      expect(dashboard.history.first.title, 'Operasi Aljabar');
      expect(dashboard.history.first.scoreText, '3/3 benar');
      expect(dashboard.history.first.resultLabel, 'Selesai');
      expect(
        dashboard.history.first.percent,
        closeTo(thetaToPercent(0.6), 1e-9),
      );
      expect(dashboard.history.last.scoreText, '1/2 benar');
    });

    test('sesi placement tanpa konsep berjudul Tes Penempatan', () {
      final dashboard = buildProgressDashboard(
        concepts: _concepts(),
        orderedIds: _order(),
        statesById: const {},
        statuses: const {},
        sessions: [
          _session(id: 'p1', theta: 0.0, startedAt: now),
        ],
        responses: const [],
        now: now,
      );

      expect(dashboard.history.single.title, 'Tes Penempatan');
      expect(dashboard.history.single.scoreText, isNull);
    });
  });
}
