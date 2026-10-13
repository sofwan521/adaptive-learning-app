import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/irt/irt_engine.dart';
import 'package:adaptive_learning_app/domain/models/ability_estimate.dart';
import 'package:adaptive_learning_app/domain/models/concept.dart';
import 'package:adaptive_learning_app/domain/models/concept_edge.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/models/response_record.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';

List<ResponseRecord> _bankResponses({required bool correct}) {
  const bs = [-2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5];
  return [
    for (final b in bs) ResponseRecord(a: 1.0, b: b, correct: correct),
  ];
}

Item _item(String id, double b, {double a = 1.0}) {
  return Item(
    id: id,
    conceptId: 'K01',
    question: 'Soal $id',
    options: const ['A', 'B', 'C', 'D'],
    correctIndex: 0,
    a: a,
    b: b,
  );
}

void main() {
  group('probability', () {
    test('P = 0.5 saat theta = b untuk berbagai a dan b', () {
      for (final a in [0.8, 1.0, 1.5, 2.0]) {
        for (final b in [-2.0, -0.5, 0.0, 1.5]) {
          expect(probability(b, a, b), closeTo(0.5, 1e-9));
        }
      }
    });

    test('P mendekati 1 saat theta jauh di atas b', () {
      expect(probability(4.0, 1.0, 0.0), greaterThan(0.98));
    });

    test('P mendekati 0 saat theta jauh di bawah b', () {
      expect(probability(-4.0, 1.0, 0.0), lessThan(0.02));
    });

    test('P monoton naik terhadap theta', () {
      expect(probability(1.0, 1.0, 0.0), greaterThan(probability(0.0, 1.0, 0.0)));
      expect(probability(0.0, 1.0, 0.0), greaterThan(probability(-1.0, 1.0, 0.0)));
    });
  });

  group('information', () {
    test('maksimum a^2/4 saat theta = b', () {
      expect(information(0.0, 1.0, 0.0), closeTo(0.25, 1e-9));
      expect(information(1.5, 2.0, 1.5), closeTo(1.0, 1e-9));
    });

    test('mengecil saat theta menjauhi b', () {
      expect(information(0.0, 1.0, 0.0), greaterThan(information(2.0, 1.0, 0.0)));
    });
  });

  group('estimateEap', () {
    test('tanpa respons mengembalikan prior', () {
      final estimate = estimateEap(const []);
      expect(estimate.theta, closeTo(0.0, 1e-6));
      expect(estimate.se, closeTo(1.0, 0.01));
    });

    test('prior kustom dihormati saat tanpa respons', () {
      final estimate = estimateEap(const [], priorMean: 1.0, priorSd: 0.5);
      expect(estimate.theta, closeTo(1.0, 0.05));
      expect(estimate.se, closeTo(0.5, 0.05));
    });

    test('semua benar menaikkan theta namun tetap hingga', () {
      final estimate = estimateEap(_bankResponses(correct: true));
      expect(estimate.theta, greaterThan(0.0));
      expect(estimate.theta, lessThanOrEqualTo(4.0));
      expect(estimate.theta.isFinite, isTrue);
      expect(estimate.se.isFinite, isTrue);
      expect(estimate.se, greaterThan(0.0));
    });

    test('semua salah menurunkan theta namun tetap hingga', () {
      final estimate = estimateEap(_bankResponses(correct: false));
      expect(estimate.theta, lessThan(0.0));
      expect(estimate.theta, greaterThanOrEqualTo(-4.0));
      expect(estimate.theta.isFinite, isTrue);
      expect(estimate.se, greaterThan(0.0));
    });

    test('simetris: benar semua vs salah semua', () {
      // Bank simetris terhadap 0 agar posteriornya cerminan sempurna.
      const symmetric = [
        ResponseRecord(a: 1.0, b: -1.0, correct: true),
        ResponseRecord(a: 1.0, b: -0.5, correct: true),
        ResponseRecord(a: 1.0, b: 0.0, correct: true),
        ResponseRecord(a: 1.0, b: 0.5, correct: true),
        ResponseRecord(a: 1.0, b: 1.0, correct: true),
      ];
      final up = estimateEap(symmetric);
      final down = estimateEap([
        for (final r in symmetric)
          ResponseRecord(a: r.a, b: r.b, correct: false),
      ]);
      expect(up.theta, closeTo(-down.theta, 1e-9));
      expect(up.se, closeTo(down.se, 1e-9));
    });

    test('SE menurun seiring jumlah respons', () {
      const mixed = [
        ResponseRecord(a: 1.2, b: -1.0, correct: true),
        ResponseRecord(a: 1.0, b: -0.5, correct: true),
        ResponseRecord(a: 1.1, b: 0.0, correct: false),
        ResponseRecord(a: 1.3, b: 0.5, correct: true),
        ResponseRecord(a: 1.0, b: 1.0, correct: false),
        ResponseRecord(a: 1.4, b: 1.5, correct: true),
        ResponseRecord(a: 1.2, b: -1.5, correct: true),
        ResponseRecord(a: 1.1, b: 2.0, correct: false),
      ];
      final se2 = estimateEap(mixed.sublist(0, 2)).se;
      final se8 = estimateEap(mixed).se;
      expect(se8, lessThan(se2));
    });

    test('deterministik untuk masukan sama', () {
      final responses = _bankResponses(correct: true);
      expect(estimateEap(responses), equals(estimateEap(responses)));
    });
  });

  group('selectNextItem', () {
    final candidates = [
      _item('q1', -2.0),
      _item('q2', -1.0),
      _item('q3', 0.0),
      _item('q4', 1.0),
      _item('q5', 2.0),
    ];

    test('memilih b terdekat theta untuk a sama', () {
      expect(selectNextItem(0.8, candidates, const {})?.id, 'q4');
      expect(selectNextItem(-1.9, candidates, const {})?.id, 'q1');
      expect(selectNextItem(0.1, candidates, const {})?.id, 'q3');
    });

    test('melewati soal yang sudah dipakai', () {
      final next = selectNextItem(0.8, candidates, const {'q4'});
      expect(next?.id, 'q3');
    });

    test('null bila kandidat kosong atau semua terpakai', () {
      expect(selectNextItem(0.0, const [], const {}), isNull);
      expect(
        selectNextItem(0.0, candidates, {'q1', 'q2', 'q3', 'q4', 'q5'}),
        isNull,
      );
    });

    test('seri diputus acak terkontrol yang deterministik', () {
      final twins = [_item('a', 0.0), _item('b', 0.0)];
      final first = selectNextItem(0.0, twins, const {}, random: Random(7));
      final second = selectNextItem(0.0, twins, const {}, random: Random(7));
      expect(first?.id, isIn(['a', 'b']));
      expect(first?.id, second?.id);
    });
  });

  group('evaluateSession', () {
    const precise = AbilityEstimate(theta: 0.5, se: 0.5);
    const baseline = 0.0;

    test('lanjut bila soal kurang dari minimal', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: 2.0, se: 0.1),
          nAnswered: 3,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.ongoing,
      );
      expect(
        evaluateSession(
          estimate: precise,
          nAnswered: 0,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.ongoing,
      );
    });

    test('dikuasai bila SE cukup dan theta di atas tau', () {
      expect(
        evaluateSession(
          estimate: precise,
          nAnswered: 4,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.mastered,
      );
    });

    test('batas SE tepat 0.6 tetap berhenti', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: 0.5, se: 0.6),
          nAnswered: 5,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.mastered,
      );
    });

    test('gagal bila berhenti namun theta di bawah tau', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: -0.5, se: 0.4),
          nAnswered: 4,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.failed,
      );
    });

    test('theta tepat sama dengan tau dihitung dikuasai', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: 0.0, se: 0.5),
          nAnswered: 4,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.mastered,
      );
    });

    test('lanjut bila SE masih besar', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: 1.5, se: 0.7),
          nAnswered: 4,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.ongoing,
      );
    });

    test('berhenti saat mencapai 8 soal walau SE besar', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: 1.0, se: 0.9),
          nAnswered: 8,
          consecutiveWrong: 0,
          tau: baseline,
        ),
        SessionDecision.mastered,
      );
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: -1.0, se: 0.9),
          nAnswered: 8,
          consecutiveWrong: 1,
          tau: baseline,
        ),
        SessionDecision.failed,
      );
    });

    test('gagal dini bila 3 salah berturut-turut', () {
      expect(
        evaluateSession(
          estimate: const AbilityEstimate(theta: 2.0, se: 0.2),
          nAnswered: 2,
          consecutiveWrong: 3,
          tau: baseline,
        ),
        SessionDecision.failed,
      );
    });

    test('2 salah berturut-turut belum gagal', () {
      expect(
        evaluateSession(
          estimate: precise,
          nAnswered: 5,
          consecutiveWrong: 2,
          tau: baseline,
        ),
        SessionDecision.mastered,
      );
    });
  });

  group('model Equatable', () {
    test('kesetaraan nilai dan copyWith', () {
      expect(
        const AbilityEstimate(theta: 1.0, se: 0.5),
        equals(const AbilityEstimate(theta: 1.0, se: 0.5)),
      );
      expect(
        const ResponseRecord(a: 1.0, b: 0.0, correct: true),
        equals(const ResponseRecord(a: 1.0, b: 0.0, correct: true)),
      );
      expect(
        const ConceptEdge(prerequisiteId: 'K01', conceptId: 'K02'),
        equals(const ConceptEdge(prerequisiteId: 'K01', conceptId: 'K02')),
      );
      expect(
        const Concept(id: 'K01', name: 'Bilangan Bulat', description: 'd'),
        equals(const Concept(id: 'K01', name: 'Bilangan Bulat', description: 'd')),
      );
      expect(
        const StudentConceptState(studentId: 's', conceptId: 'K01'),
        equals(const StudentConceptState(studentId: 's', conceptId: 'K01')),
      );

      const item = Item(
        id: 'i1',
        conceptId: 'K01',
        correctIndex: 2,
      );
      expect(item.copyWith(a: 1.5).a, 1.5);
      expect(item.copyWith(a: 1.5).correctIndex, 2);
    });

    test('status konsep memiliki label Indonesia', () {
      expect(ConceptStatus.locked.label, 'Terkunci');
      expect(ConceptStatus.mastered.label, 'Dikuasai');
    });
  });
}
