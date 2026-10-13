import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/models/concept.dart';
import '../../../domain/models/concept_status.dart';

/// BottomSheet detail konsep dari peta.
///
/// - Node terbuka (terbuka/dipelajari/dikuasai): judul, deskripsi,
///   status, dan tombol `Pelajari Materi` menuju kuis konsep.
/// - Node terkunci: judul, status, dan daftar prasyarat yang
///   belum dikuasai (bukan tombol aksi).
Future<void> showConceptDetailSheet(
  BuildContext context, {
  required Concept concept,
  required ConceptStatus status,
  required KnowledgeGraph graph,
  required Map<String, ConceptStatus> statuses,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      if (status == ConceptStatus.locked) {
        final missing = graph
            .ancestorsOf(concept.id)
            .where((id) => (statuses[id] ?? ConceptStatus.locked) !=
                ConceptStatus.mastered)
            .toList()
          ..sort((a, b) => graph
              .topologicalOrder()
              .indexOf(a)
              .compareTo(graph.topologicalOrder().indexOf(b)));
        return _SheetBody(
          concept: concept,
          status: status,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prasyarat yang belum dikuasai:',
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (missing.isEmpty)
                Text(
                  'Selesaikan konsep sebelumnya untuk membuka materi ini.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                )
              else
                for (final id in missing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Theme.of(sheetContext).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _conceptLabel(graph, id),
                            style:
                                Theme.of(sheetContext).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      }
      return _SheetBody(
        concept: concept,
        status: status,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              key: const Key('concept-sheet-study'),
              label: 'Pelajari Materi',
              icon: Icons.menu_book,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.studentMaterial(concept.id));
              },
            ),
          ],
        ),
      );
    },
  );
}

String _conceptLabel(KnowledgeGraph graph, String id) {
  try {
    final concept = graph.concept(id);
    final code = concept.code.isEmpty ? concept.id : concept.code;
    return '$code — ${concept.name}';
  } catch (_) {
    return id;
  }
}

class _SheetBody extends StatelessWidget {
  final Concept concept;
  final ConceptStatus status;
  final Widget child;

  const _SheetBody({
    required this.concept,
    required this.status,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(concept.name, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          ConceptStatusChip(status: status),
          const SizedBox(height: 12),
          if (concept.description.isNotEmpty) ...[
            Text(concept.description, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
