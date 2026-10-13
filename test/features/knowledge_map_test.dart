import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/graph/knowledge_graph.dart';
import 'package:adaptive_learning_app/domain/models/concept.dart';
import 'package:adaptive_learning_app/domain/models/concept_edge.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/features/knowledge_map/application/knowledge_map_layout.dart';
import 'package:adaptive_learning_app/features/knowledge_map/presentation/concept_detail_sheet.dart';
import 'package:adaptive_learning_app/features/knowledge_map/presentation/knowledge_map_legend.dart';
import 'package:adaptive_learning_app/features/knowledge_map/presentation/knowledge_map_view.dart';

/// Graf seed K01..K08 dengan nama ringkas.
KnowledgeGraph seedGraph() {
  const names = {
    'K01': 'Bilangan Bulat',
    'K02': 'Operasi Aljabar',
    'K03': 'Persamaan Linear',
    'K04': 'Pertidaksamaan Linear',
    'K05': 'Sistem Persamaan Linear',
    'K06': 'Pecahan',
    'K07': 'Perbandingan dan Skala',
    'K08': 'Fungsi Linear',
  };
  return KnowledgeGraph(
    concepts: [
      for (final entry in names.entries)
        Concept(
          id: entry.key,
          code: entry.key,
          name: entry.value,
          description: 'Deskripsi ${entry.value}.',
        ),
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

/// Status: K01 dikuasai, K02/K06 terbuka, K03 dipelajari, sisanya terkunci.
Map<String, ConceptStatus> seedStatuses() => const {
      'K01': ConceptStatus.mastered,
      'K02': ConceptStatus.open,
      'K03': ConceptStatus.learning,
      'K04': ConceptStatus.locked,
      'K05': ConceptStatus.locked,
      'K06': ConceptStatus.open,
      'K07': ConceptStatus.locked,
      'K08': ConceptStatus.locked,
    };

Future<void> _pumpMap(
  WidgetTester tester, {
  ValueChanged<String>? onNodeTap,
}) async {
  final graph = seedGraph();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: KnowledgeMapView(
            graph: graph,
            statuses: seedStatuses(),
            onNodeTap: onNodeTap ??
                (id) {
                  final context = tester.element(
                    find.byKey(const Key('knowledge-map-canvas')),
                  );
                  showConceptDetailSheet(
                    context,
                    concept: graph.concept(id),
                    status: seedStatuses()[id]!,
                    graph: graph,
                    statuses: seedStatuses(),
                  );
                },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Titik global tengah node [id] pada kanvas yang sedang tampil.
Offset _nodeCenter(WidgetTester tester, String id) {
  final topLeft =
      tester.getTopLeft(find.byKey(const Key('knowledge-map-canvas')));
  final center = KnowledgeMapLayout.fromGraph(seedGraph()).centers[id]!;
  return topLeft + center;
}

void main() {
  group('KnowledgeMapView', () {
    testWidgets('menampilkan kanvas graf seed', (tester) async {
      await _pumpMap(tester);

      expect(
        find.byKey(const Key('knowledge-map-canvas')),
        findsOneWidget,
      );
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ketuk node terbuka membuka detail + Pelajari Materi',
        (tester) async {
      await _pumpMap(tester);

      await tester.tapAt(_nodeCenter(tester, 'K02'));
      await tester.pumpAndSettle();

      expect(find.text('Operasi Aljabar'), findsWidgets);
      expect(find.text('Deskripsi Operasi Aljabar.'), findsOneWidget);
      expect(find.text('Terbuka'), findsWidgets);
      expect(find.byKey(const Key('concept-sheet-study')), findsOneWidget);
      expect(find.text('Pelajari Materi'), findsOneWidget);
    });

    testWidgets('ketuk node terkunci menampilkan prasyarat belum dikuasai',
        (tester) async {
      await _pumpMap(tester);

      // K08 di baris terbawah: geser kanvas agar masuk viewport.
      await tester.drag(
        find.byKey(const Key('knowledge-map-canvas')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(_nodeCenter(tester, 'K08'));
      await tester.pumpAndSettle();

      expect(find.text('Fungsi Linear'), findsWidgets);
      expect(find.text('Terkunci'), findsWidgets);
      expect(
        find.text('Prasyarat yang belum dikuasai:'),
        findsOneWidget,
      );
      // K05, K07, dan leluhurnya yang belum mastered tercantum.
      expect(find.textContaining('Sistem Persamaan Linear'), findsWidgets);
      expect(find.textContaining('Perbandingan dan Skala'), findsWidgets);
      expect(find.byKey(const Key('concept-sheet-study')), findsNothing);
    });

    testWidgets('ketuk celah antar-node tidak membuka apa pun',
        (tester) async {
      final tapped = <String>[];
      await _pumpMap(tester, onNodeTap: tapped.add);

      final layout = KnowledgeMapLayout.fromGraph(seedGraph());
      final topLeft =
          tester.getTopLeft(find.byKey(const Key('knowledge-map-canvas')));
      await tester.tapAt(topLeft + const Offset(4, 4));
      await tester.pump();

      expect(layout.nodeAt(const Offset(4, 4)), isNull);
      expect(tapped, isEmpty);
    });
  });

  group('KnowledgeMapLegend', () {
    testWidgets('menampilkan empat status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: KnowledgeMapLegend()),
        ),
      );

      expect(find.text('Legenda'), findsOneWidget);
      expect(find.text('Terkunci'), findsOneWidget);
      expect(find.text('Terbuka'), findsOneWidget);
      expect(find.text('Dipelajari'), findsOneWidget);
      expect(find.text('Dikuasai'), findsOneWidget);
    });
  });
}
