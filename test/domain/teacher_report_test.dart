import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/class_info.dart';

QuizSession _session({
  required String id,
  required String? conceptId,
  required double? theta,
  QuizSessionStatus status = QuizSessionStatus.finished,
}) {
  return QuizSession(
    id: id,
    studentId: 'siswa-1',
    conceptId: conceptId,
    status: status,
    finalTheta: theta,
    startedAt: DateTime(2026, 10, 13),
  );
}

void main() {
  group('rankFailedConcepts', () {
    test('urut berdasarkan persentase gagal menurun', () {
      final ranked = rankFailedConcepts(
        sessions: [
          _session(id: 'a1', conceptId: 'K01', theta: -1.0),
          _session(id: 'a2', conceptId: 'K01', theta: 1.0),
          _session(id: 'b1', conceptId: 'K02', theta: -2.0),
          _session(id: 'b2', conceptId: 'K02', theta: -1.5),
          _session(id: 'c1', conceptId: 'K03', theta: 2.0),
        ],
        taus: const {'K01': 0, 'K02': 0, 'K03': 0},
      );

      expect(
        ranked.map((r) => r.conceptId),
        ['K02', 'K01', 'K03'],
      );
      expect(ranked.first.failRate, 1.0);
      expect(ranked[1], const ConceptFailRate(
        conceptId: 'K01',
        sessions: 2,
        failed: 1,
      ));
      expect(ranked.last.failRate, 0.0);
    });

    test('seri dipecah jumlah sesi lalu id', () {
      final ranked = rankFailedConcepts(
        sessions: [
          _session(id: 'a1', conceptId: 'K02', theta: -1.0),
          _session(id: 'b1', conceptId: 'K01', theta: -1.0),
          _session(id: 'b2', conceptId: 'K01', theta: -2.0),
        ],
        taus: const {},
      );

      // Keduanya 100% gagal; K01 lebih dulu karena sesi lebih banyak.
      expect(ranked.map((r) => r.conceptId), ['K01', 'K02']);
    });

    test('ambang per konsep dipakai, default 0', () {
      final ranked = rankFailedConcepts(
        sessions: [
          _session(id: 'a1', conceptId: 'K03', theta: 0.1),
        ],
        taus: const {'K03': 0.2},
      );

      expect(ranked.single.failed, 1);
      expect(ranked.single.failRate, 1.0);
    });

    test('abaikan sesi berjalan, tanpa konsep, tanpa theta', () {
      final ranked = rankFailedConcepts(
        sessions: [
          _session(
            id: 'a1',
            conceptId: 'K01',
            theta: -5.0,
            status: QuizSessionStatus.ongoing,
          ),
          _session(id: 'a2', conceptId: null, theta: -5.0),
          _session(id: 'a3', conceptId: 'K01', theta: null),
          _session(id: 'a4', conceptId: 'K01', theta: 1.0),
        ],
        taus: const {},
      );

      expect(ranked, hasLength(1));
      expect(ranked.single.sessions, 1);
      expect(ranked.single.failed, 0);
    });

    test('kosong bila tak ada sesi selesai yang sah', () {
      expect(
        rankFailedConcepts(sessions: const [], taus: const {}),
        isEmpty,
      );
    });
  });
}
