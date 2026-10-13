import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/graph/knowledge_graph.dart';
import 'package:adaptive_learning_app/domain/models/concept.dart';
import 'package:adaptive_learning_app/domain/models/concept_edge.dart';
import 'package:adaptive_learning_app/features/knowledge_map/application/knowledge_map_layout.dart';

/// Graf Matematika dasar sesuai seed (supabase/seed.sql).
KnowledgeGraph seedGraph() {
  const ids = ['K01', 'K02', 'K03', 'K04', 'K05', 'K06', 'K07', 'K08'];
  return KnowledgeGraph(
    concepts: [
      for (final id in ids)
        Concept(id: id, code: id, name: 'Konsep $id', description: ''),
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

/// Graf sintetis 20 node: 1 akar, 9 anak, 9 cucu, 1 gabungan.
KnowledgeGraph wideGraph() {
  final concepts = <Concept>[
    const Concept(id: 'R', code: 'R', name: 'Akar', description: ''),
    for (var i = 0; i < 9; i++)
      Concept(id: 'C$i', code: 'C$i', name: 'Anak $i', description: ''),
    for (var i = 0; i < 9; i++)
      Concept(id: 'L$i', code: 'L$i', name: 'Daun $i', description: ''),
    const Concept(id: 'M', code: 'M', name: 'Gabungan', description: ''),
  ];
  final edges = <ConceptEdge>[
    for (var i = 0; i < 9; i++)
      ConceptEdge(prerequisiteId: 'R', conceptId: 'C$i'),
    for (var i = 0; i < 9; i++)
      ConceptEdge(prerequisiteId: 'C$i', conceptId: 'L$i'),
    const ConceptEdge(prerequisiteId: 'L0', conceptId: 'M'),
    const ConceptEdge(prerequisiteId: 'L1', conceptId: 'M'),
  ];
  return KnowledgeGraph(concepts: concepts, edges: edges);
}

bool _overlaps(KnowledgeMapLayout layout) {
  final rects = layout.rects.values.toList();
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      if (rects[i].overlaps(rects[j])) return true;
    }
  }
  return false;
}

void main() {
  group('computeKnowledgeDepths', () {
    test('kedalaman graf seed berlapis benar', () {
      final depths = computeKnowledgeDepths(seedGraph());

      expect(depths['K01'], 0);
      expect(depths['K02'], 1);
      expect(depths['K06'], 1);
      expect(depths['K03'], 2);
      expect(depths['K07'], 2);
      expect(depths['K04'], 3);
      expect(depths['K05'], 3);
      expect(depths['K08'], 4);
    });

    test('jalur terpanjang menang saat beberapa prasyarat', () {
      final depths = computeKnowledgeDepths(seedGraph());

      // K08 lewat K05 (kedalaman 3) dan K07 (kedalaman 2).
      expect(depths['K08'], 4);
    });

    test('prasyarat selalu lebih dangkal dari konsep', () {
      final graph = seedGraph();
      final depths = computeKnowledgeDepths(graph);

      for (final id in graph.conceptIds) {
        for (final parent in graph.prerequisitesOf(id)) {
          expect(depths[parent], lessThan(depths[id]!));
        }
      }
    });
  });

  group('KnowledgeMapLayout.fromGraph', () {
    test('node satu lapisan sejajar horizontal', () {
      final layout = KnowledgeMapLayout.fromGraph(seedGraph());

      // Lapisan 1: K02 dan K06 punya y tengah sama, x berbeda.
      final k02 = layout.centers['K02']!;
      final k06 = layout.centers['K06']!;
      expect(k02.dy, k06.dy);
      expect(k02.dx, isNot(k06.dx));

      // Lapisan 0 di atas lapisan 4.
      expect(
        layout.centers['K01']!.dy,
        lessThan(layout.centers['K08']!.dy),
      );
    });

    test('tidak tumpang tindih untuk graf seed (8 node)', () {
      expect(_overlaps(KnowledgeMapLayout.fromGraph(seedGraph())), isFalse);
    });

    test('tidak tumpang tindih untuk graf lebar (20 node)', () {
      final layout = KnowledgeMapLayout.fromGraph(wideGraph());

      expect(layout.rects, hasLength(20));
      expect(_overlaps(layout), isFalse);
      // Lapisan terlebar (9 anak) tetap punya celah horizontal.
      final first = layout.rects['C0']!;
      final second = layout.rects['C1']!;
      expect(
        second.left - first.right,
        greaterThanOrEqualTo(KnowledgeMapLayout.horizontalGap - 0.001),
      );
    });

    test('ukuran kartu dan kanvas konsisten', () {
      final layout = KnowledgeMapLayout.fromGraph(seedGraph());

      for (final rect in layout.rects.values) {
        expect(rect.width, KnowledgeMapLayout.nodeWidth);
        expect(rect.height, KnowledgeMapLayout.nodeHeight);
      }
      expect(layout.size.width, greaterThan(KnowledgeMapLayout.nodeWidth));
      expect(layout.size.height, greaterThan(KnowledgeMapLayout.nodeHeight));
    });
  });

  group('nodeAt', () {
    test('titik tengah node tepat mengenai id-nya', () {
      final layout = KnowledgeMapLayout.fromGraph(seedGraph());

      for (final entry in layout.centers.entries) {
        expect(layout.nodeAt(entry.value), entry.key);
      }
    });

    test('celah antar-node tidak mengenai apa pun', () {
      final layout = KnowledgeMapLayout.fromGraph(seedGraph());

      final k02 = layout.rects['K02']!;
      final k06 = layout.rects['K06']!;
      // Keduanya satu lapisan; titik tengah celahnya bukan node.
      final left = k02.left < k06.left ? k02 : k06;
      final right = identical(left, k02) ? k06 : k02;
      final gapMid = Offset(
        (left.right + right.left) / 2,
        (left.center.dy + right.center.dy) / 2,
      );
      expect(left.right, lessThan(right.left));
      expect(layout.nodeAt(gapMid), isNull);
    });

    test('jauh di luar kanvas tidak mengenai apa pun', () {
      final layout = KnowledgeMapLayout.fromGraph(seedGraph());

      expect(layout.nodeAt(const Offset(-1000, -1000)), isNull);
      expect(
        layout.nodeAt(layout.size.bottomRight(const Offset(500, 500))),
        isNull,
      );
    });

    test('sudut dalam kartu masih mengenai node', () {
      final layout = KnowledgeMapLayout.fromGraph(seedGraph());

      final rect = layout.rects['K08']!;
      expect(layout.nodeAt(rect.topLeft + const Offset(1, 1)), 'K08');
      expect(
        layout.nodeAt(rect.bottomRight - const Offset(1, 1)),
        'K08',
      );
    });
  });
}
