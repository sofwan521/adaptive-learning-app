import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/graph/knowledge_graph.dart';
import 'package:adaptive_learning_app/domain/models/concept.dart';
import 'package:adaptive_learning_app/domain/models/concept_edge.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';

/// Graf Matematika dasar sesuai seed (supabase/seed.sql).
KnowledgeGraph mathGraph() {
  const ids = ['K01', 'K02', 'K03', 'K04', 'K05', 'K06', 'K07', 'K08'];
  return KnowledgeGraph(
    concepts: [
      for (final id in ids)
        Concept(id: id, name: 'Konsep $id', description: 'Deskripsi $id'),
    ],
    edges: const [
      ConceptEdge(prerequisiteId: 'K01', conceptId: 'K02'),
      ConceptEdge(prerequisiteId: 'K02', conceptId: 'K03'),
      ConceptEdge(prerequisiteId: 'K03', conceptId: 'K04'),
      ConceptEdge(prerequisiteId: 'K03', conceptId: 'K05'),
      ConceptEdge(prerequisiteId: 'K01', conceptId: 'K06'),
      ConceptEdge(prerequisiteId: 'K06', conceptId: 'K07'),
      ConceptEdge(prerequisiteId: 'K05', conceptId: 'K08'),
      ConceptEdge(prerequisiteId: 'K07', conceptId: 'K08'),
    ],
  );
}

StudentConceptState _state(
  String conceptId, {
  ConceptStatus status = ConceptStatus.learning,
  int nAnswered = 5,
}) {
  return StudentConceptState(
    studentId: 'siswa-1',
    conceptId: conceptId,
    status: status,
    nAnswered: nAnswered,
  );
}

StudentConceptState _mastered(String conceptId) => _state(
      conceptId,
      status: ConceptStatus.mastered,
      nAnswered: 8,
    );

void main() {
  group('konstruksi dan struktur', () {
    test('graf K01..K08 terbentuk tanpa siklus', () {
      final graph = mathGraph();
      expect(graph.hasCycle(), isFalse);
      expect(graph.conceptIds,
          {'K01', 'K02', 'K03', 'K04', 'K05', 'K06', 'K07', 'K08'});
    });

    test('prerequisitesOf dan dependentsOf langsung', () {
      final graph = mathGraph();
      expect(graph.prerequisitesOf('K08'), ['K05', 'K07']);
      expect(graph.prerequisitesOf('K01'), isEmpty);
      expect(graph.dependentsOf('K03'), ['K04', 'K05']);
      expect(graph.dependentsOf('K08'), isEmpty);
    });

    test('ancestorsOf mencakup prasyarat tak langsung', () {
      final graph = mathGraph();
      expect(graph.ancestorsOf('K08'),
          {'K01', 'K02', 'K03', 'K05', 'K06', 'K07'});
      expect(graph.ancestorsOf('K03'), {'K01', 'K02'});
      expect(graph.ancestorsOf('K01'), isEmpty);
    });

    test('id tak dikenal melempar ArgumentError', () {
      final graph = mathGraph();
      expect(() => graph.prerequisitesOf('ZZ'), throwsArgumentError);
      expect(
        () => graph.buildRemedialPlan('ZZ', const {}),
        throwsArgumentError,
      );
    });
  });

  group('deteksi siklus', () {
    test('siklus melempar GraphCycleException', () {
      expect(
        () => KnowledgeGraph(
          concepts: const [
            Concept(id: 'A', name: 'A', description: ''),
            Concept(id: 'B', name: 'B', description: ''),
          ],
          edges: const [
            ConceptEdge(prerequisiteId: 'A', conceptId: 'B'),
            ConceptEdge(prerequisiteId: 'B', conceptId: 'A'),
          ],
        ),
        throwsA(isA<GraphCycleException>()),
      );
    });

    test('self-loop melempar GraphCycleException', () {
      expect(
        () => KnowledgeGraph(
          concepts: const [
            Concept(id: 'A', name: 'A', description: ''),
          ],
          edges: const [
            ConceptEdge(prerequisiteId: 'A', conceptId: 'A'),
          ],
        ),
        throwsA(isA<GraphCycleException>()),
      );
    });

    test('siklus di graf K01..K08 tertolak', () {
      expect(
        () => KnowledgeGraph(
          concepts: [
            for (final id in ['K01', 'K05', 'K08'])
              Concept(id: id, name: id, description: ''),
          ],
          edges: const [
            ConceptEdge(prerequisiteId: 'K01', conceptId: 'K05'),
            ConceptEdge(prerequisiteId: 'K05', conceptId: 'K08'),
            ConceptEdge(prerequisiteId: 'K08', conceptId: 'K01'),
          ],
        ),
        throwsA(isA<GraphCycleException>()),
      );
    });
  });

  group('topologicalOrder', () {
    test('valid: prasyarat selalu sebelum lanjutan', () {
      final graph = mathGraph();
      final order = graph.topologicalOrder();
      expect(order.toSet(), graph.conceptIds);
      const edges = [
        ('K01', 'K02'),
        ('K02', 'K03'),
        ('K03', 'K04'),
        ('K03', 'K05'),
        ('K01', 'K06'),
        ('K06', 'K07'),
        ('K05', 'K08'),
        ('K07', 'K08'),
      ];
      for (final (pre, post) in edges) {
        expect(
          order.indexOf(pre),
          lessThan(order.indexOf(post)),
          reason: '$pre harus sebelum $post',
        );
      }
    });
  });

  group('computeStatuses (lock/unlock)', () {
    test('tanpa state: K01 open, sisanya locked', () {
      final statuses = mathGraph().computeStatuses(const {});
      expect(statuses['K01'], ConceptStatus.open);
      for (final id in ['K02', 'K03', 'K04', 'K05', 'K06', 'K07', 'K08']) {
        expect(statuses[id], ConceptStatus.locked, reason: id);
      }
    });

    test('K01 mastered membuka K02 dan K06', () {
      final statuses = mathGraph().computeStatuses({'K01': _mastered('K01')});
      expect(statuses['K02'], ConceptStatus.open);
      expect(statuses['K06'], ConceptStatus.open);
      expect(statuses['K03'], ConceptStatus.locked);
      expect(statuses['K08'], ConceptStatus.locked);
    });

    test('rantai K01..K03 mastered membuka K04 dan K05', () {
      final statuses = mathGraph().computeStatuses({
        'K01': _mastered('K01'),
        'K02': _mastered('K02'),
        'K03': _mastered('K03'),
      });
      expect(statuses['K04'], ConceptStatus.open);
      expect(statuses['K05'], ConceptStatus.open);
      expect(statuses['K06'], ConceptStatus.open);
    });

    test('pernah dikerjakan tetapi belum lulus menjadi learning', () {
      final statuses = mathGraph().computeStatuses({
        'K01': _mastered('K01'),
        'K02': _state('K02'),
      });
      expect(statuses['K02'], ConceptStatus.learning);
    });

    test('mastered tetap mastered', () {
      final statuses = mathGraph().computeStatuses({
        'K05': _mastered('K05'),
      });
      expect(statuses['K05'], ConceptStatus.mastered);
      // Prasyaratnya belum mastered sehingga tetangganya terkunci.
      expect(statuses['K08'], ConceptStatus.locked);
    });
  });

  group('buildRemedialPlan', () {
    test('remedial K03 saat K02 lemah menunjuk K02', () {
      final plan = mathGraph().buildRemedialPlan('K03', {
        'K01': ConceptStatus.mastered,
        'K02': ConceptStatus.learning,
        'K03': ConceptStatus.learning,
      });
      expect(plan.failedConceptId, 'K03');
      expect(plan.weakIds, {'K02'});
      expect(plan.rootIds, {'K02'});
      expect(plan.orderedPath, ['K02', 'K03']);
      expect(plan.isRepeatOnly, isFalse);
    });

    test('remedial K08 saat K05 dan K07 lemah menunjuk kedua akar', () {
      final plan = mathGraph().buildRemedialPlan('K08', {
        'K01': ConceptStatus.mastered,
        'K02': ConceptStatus.mastered,
        'K03': ConceptStatus.mastered,
        'K05': ConceptStatus.learning,
        'K06': ConceptStatus.mastered,
        'K07': ConceptStatus.learning,
        'K08': ConceptStatus.learning,
      });
      expect(plan.weakIds, {'K05', 'K07'});
      expect(plan.rootIds, {'K05', 'K07'});
      expect(plan.orderedPath.last, 'K08');
      expect(plan.orderedPath.length, 3);
      expect(plan.orderedPath.toSet(), {'K05', 'K07', 'K08'});
    });

    test('akar menyempit ke K03 bila K05 lemah karena K03', () {
      final plan = mathGraph().buildRemedialPlan('K08', {
        'K01': ConceptStatus.mastered,
        'K02': ConceptStatus.mastered,
        'K03': ConceptStatus.learning,
        'K06': ConceptStatus.mastered,
        'K07': ConceptStatus.mastered,
        'K08': ConceptStatus.learning,
      });
      expect(plan.weakIds, {'K03', 'K05'});
      expect(plan.rootIds, {'K03'});
      expect(plan.orderedPath, ['K03', 'K05', 'K08']);
    });

    test('tanpa prasyarat lemah: ulangi materi itu sendiri', () {
      final plan = mathGraph().buildRemedialPlan('K04', {
        'K01': ConceptStatus.mastered,
        'K02': ConceptStatus.mastered,
        'K03': ConceptStatus.mastered,
        'K04': ConceptStatus.learning,
      });
      expect(plan.weakIds, isEmpty);
      expect(plan.rootIds, isEmpty);
      expect(plan.orderedPath, ['K04']);
      expect(plan.isRepeatOnly, isTrue);
    });

    test('jalur remedial selalu topologis dan diakhiri konsep gagal', () {
      final graph = mathGraph();
      final plan = graph.buildRemedialPlan('K08', {
        'K01': ConceptStatus.mastered,
        'K02': ConceptStatus.learning,
        'K06': ConceptStatus.mastered,
        'K07': ConceptStatus.learning,
        'K08': ConceptStatus.learning,
      });
      // Setiap edge yang kedua ujungnya ada di jalur harus berurutan benar.
      const edges = [
        ('K01', 'K02'),
        ('K02', 'K03'),
        ('K03', 'K04'),
        ('K03', 'K05'),
        ('K01', 'K06'),
        ('K06', 'K07'),
        ('K05', 'K08'),
        ('K07', 'K08'),
      ];
      for (final (pre, post) in edges) {
        if (plan.orderedPath.contains(pre) &&
            plan.orderedPath.contains(post)) {
          expect(
            plan.orderedPath.indexOf(pre),
            lessThan(plan.orderedPath.indexOf(post)),
            reason: '$pre harus sebelum $post',
          );
        }
      }
      expect(plan.orderedPath.last, 'K08');
    });
  });

  group('newlyUnlocked', () {
    test('menguasai K01 membuka K02 dan K06', () {
      expect(
        mathGraph().newlyUnlocked('K01', {
          'K01': ConceptStatus.mastered,
        }),
        {'K02', 'K06'},
      );
    });

    test('menguasai K03 membuka K04 dan K05', () {
      expect(
        mathGraph().newlyUnlocked('K03', {
          'K01': ConceptStatus.mastered,
          'K02': ConceptStatus.mastered,
          'K03': ConceptStatus.mastered,
        }),
        {'K04', 'K05'},
      );
    });

    test('tanpa dependen yang siap: himpunan kosong', () {
      expect(
        mathGraph().newlyUnlocked('K08', {
          'K08': ConceptStatus.mastered,
        }),
        isEmpty,
      );
    });
  });
}
