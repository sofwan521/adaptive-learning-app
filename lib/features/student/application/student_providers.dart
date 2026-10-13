import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/gamification_repository_impl.dart';
import '../../../data/repositories/progress_repository_impl.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/models/concept.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/gamification_state.dart';
import '../../../domain/repositories/concept_repository.dart';

// Catatan arsitektur: tiap provider mengambil datanya sendiri dari
// repository (tanpa rantai `.future` antar-provider yang berstatus
// visibleForTesting pada Riverpod 3). Uji memakai container dengan
// retry dinonaktifkan agar galat langsung terlihat.

/// Graf pengetahuan dari katalog backend.
final knowledgeGraphProvider = FutureProvider<KnowledgeGraph>((ref) async {
  final repository = ref.watch(conceptRepositoryProvider);
  return _loadGraph(repository);
});

Future<KnowledgeGraph> _loadGraph(ConceptRepository repository) async {
  final concepts = await repository.fetchConcepts();
  final edges = await repository.fetchEdges();
  return KnowledgeGraph(concepts: concepts, edges: edges);
}

/// Status tiap konsep untuk siswa aktif.
final conceptStatusesProvider =
    FutureProvider<Map<String, ConceptStatus>>((ref) async {
  final concepts = ref.watch(conceptRepositoryProvider);
  final progress = ref.watch(progressRepositoryProvider);
  final graph = await _loadGraph(concepts);
  final states = await progress.loadConceptStates();
  return graph.computeStatuses(
    {for (final state in states) state.conceptId: state},
  );
});

/// Konsep lanjutan: learning terakhir menurut urutan topologis,
/// atau open pertama bila tak ada yang berstatus learning.
/// Null bila belum ada konsep terbuka.
final continueConceptProvider = FutureProvider<Concept?>((ref) async {
  final concepts = ref.watch(conceptRepositoryProvider);
  final progress = ref.watch(progressRepositoryProvider);
  final graph = await _loadGraph(concepts);
  final states = await progress.loadConceptStates();
  final statuses = graph.computeStatuses(
    {for (final state in states) state.conceptId: state},
  );
  Concept? firstOpen;
  Concept? lastLearning;
  for (final id in graph.topologicalOrder()) {
    final status = statuses[id];
    if (status == ConceptStatus.learning) {
      lastLearning = graph.concept(id);
    } else if (status == ConceptStatus.open) {
      firstOpen ??= graph.concept(id);
    }
  }
  return lastLearning ?? firstOpen;
});

/// Status gamifikasi (XP dan streak) siswa aktif.
final gamificationProvider = FutureProvider<GamificationState>((ref) {
  return ref.watch(gamificationRepositoryProvider).load();
});

/// Kemajuan harian: soal terjawab hari ini terhadap target.
final dailyProgressProvider =
    FutureProvider<({int answered, int target})>((ref) async {
  const target = AppConstants.dailyQuestionTarget;
  final answered =
      await ref.watch(progressRepositoryProvider).countResponsesToday();
  return (answered: answered, target: target);
});

/// Muat ulang seluruh ringkasan belajar (untuk tombol coba lagi).
void refreshStudySummary(WidgetRef ref) {
  ref.invalidate(knowledgeGraphProvider);
  ref.invalidate(conceptStatusesProvider);
  ref.invalidate(continueConceptProvider);
  ref.invalidate(gamificationProvider);
  ref.invalidate(dailyProgressProvider);
}
