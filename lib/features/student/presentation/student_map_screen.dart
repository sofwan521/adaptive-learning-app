import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/models/concept_status.dart';
import '../../knowledge_map/presentation/concept_detail_sheet.dart';
import '../../knowledge_map/presentation/knowledge_map_legend.dart';
import '../../knowledge_map/presentation/knowledge_map_view.dart';
import '../application/student_providers.dart';

/// Peta konsep siswa: graf prasyarat interaktif.
///
/// Memakai [KnowledgeMapView] (zoom, geser, ketuk node) beserta
/// [KnowledgeMapLegend]. Ketuk node terbuka menampilkan detail dan
/// tombol Pelajari Materi; ketuk node terkunci menampilkan
/// prasyarat yang belum dikuasai.
class StudentMapScreen extends ConsumerWidget {
  const StudentMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphAsync = ref.watch(knowledgeGraphProvider);
    final statusesAsync = ref.watch(conceptStatusesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Peta Konsep')),
      body: graphAsync.when(
        data: (graph) => statusesAsync.when(
          data: (statuses) {
            if (graph.conceptIds.isEmpty) {
              return const EmptyView(
                message: 'Belum ada konsep.',
                icon: Icons.map_outlined,
              );
            }
            return _MapBody(graph: graph, statuses: statuses);
          },
          loading: () =>
              const LoadingView(message: 'Memuat status konsep…'),
          error: (error, _) => ErrorView(
            message: _friendlyError(error),
            onRetry: () => refreshStudySummary(ref),
          ),
        ),
        loading: () => const LoadingView(message: 'Memuat peta konsep…'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => refreshStudySummary(ref),
        ),
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is AppException) return error.message;
    return 'Gagal memuat peta. Silakan coba lagi.';
  }
}

class _MapBody extends StatelessWidget {
  final KnowledgeGraph graph;
  final Map<String, ConceptStatus> statuses;

  const _MapBody({required this.graph, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: KnowledgeMapView(
                graph: graph,
                statuses: statuses,
                onNodeTap: (id) {
                  ConceptStatus status;
                  try {
                    status = statuses[id] ?? ConceptStatus.locked;
                    final concept = graph.concept(id);
                    showConceptDetailSheet(
                      context,
                      concept: concept,
                      status: status,
                      graph: graph,
                      statuses: statuses,
                    );
                  } catch (_) {
                    // Id tak dikenal: abaikan ketukan.
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const KnowledgeMapLegend(),
        ],
      ),
    );
  }
}
