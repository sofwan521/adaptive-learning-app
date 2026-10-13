// Knowledge Graph AdaptiLearn: prasyarat antar-konsep, status,
// dan jalur remedial.
//
// Logika murni — tanpa import Flutter.
import 'dart:collection';

import 'package:equatable/equatable.dart';

import '../models/concept.dart';
import '../models/concept_edge.dart';
import '../models/concept_status.dart';
import '../models/student_concept_state.dart';

/// Dilempar saat graf konsep mengandung siklus.
class GraphCycleException implements Exception {
  /// Node pembentuk siklus (kosong bila tak diketahui).
  final List<String> cycle;

  const GraphCycleException([this.cycle = const []]);

  @override
  String toString() => cycle.isEmpty
      ? 'GraphCycleException: graf konsep memiliki siklus.'
      : 'GraphCycleException: siklus ${cycle.join(' -> ')}.';
}

/// Rencana remedial untuk satu konsep yang gagal.
class RemedialPlan extends Equatable {
  /// Konsep yang gagal dikuasai.
  final String failedConceptId;

  /// Himpunan lemah W: prasyarat (langsung/tak langsung) yang belum mastered.
  final Set<String> weakIds;

  /// Akar masalah R: anggota W yang semua prasyaratnya sudah mastered.
  final Set<String> rootIds;

  /// Jalur belajar: topologis R, lalu sisa W, lalu konsep awal.
  /// Bila [weakIds] kosong, hanya berisi konsep awal (mengulang materi).
  final List<String> orderedPath;

  const RemedialPlan({
    required this.failedConceptId,
    this.weakIds = const {},
    this.rootIds = const {},
    required this.orderedPath,
  });

  /// True bila tak ada prasyarat lemah (cukup mengulang materi).
  bool get isRepeatOnly => weakIds.isEmpty;

  @override
  List<Object?> get props => [failedConceptId, weakIds, rootIds, orderedPath];
}

/// Graf prasyarat antar-konsep yang tervalidasi asiklik.
class KnowledgeGraph {
  final Map<String, Concept> _concepts;
  final Map<String, List<String>> _prerequisites;
  final Map<String, List<String>> _dependents;
  List<String>? _topoCache;

  KnowledgeGraph._(this._concepts, this._prerequisites, this._dependents);

  /// Membangun graf dari [concepts] dan [edges].
  ///
  /// Melempar [ArgumentError] bila ada id duplikat atau edge menunjuk
  /// konsep tak dikenal, dan [GraphCycleException] bila ada siklus
  /// (termasuk self-loop).
  factory KnowledgeGraph({
    required List<Concept> concepts,
    List<ConceptEdge> edges = const [],
  }) {
    final map = <String, Concept>{};
    for (final concept in concepts) {
      if (map.containsKey(concept.id)) {
        throw ArgumentError('Id konsep duplikat: ${concept.id}.');
      }
      map[concept.id] = concept;
    }

    final prerequisites = <String, List<String>>{
      for (final id in map.keys) id: [],
    };
    final dependents = <String, List<String>>{
      for (final id in map.keys) id: [],
    };
    for (final edge in edges) {
      if (!map.containsKey(edge.prerequisiteId)) {
        throw ArgumentError(
            'Prasyarat tak dikenal: ${edge.prerequisiteId}.');
      }
      if (!map.containsKey(edge.conceptId)) {
        throw ArgumentError('Konsep tak dikenal: ${edge.conceptId}.');
      }
      if (!prerequisites[edge.conceptId]!.contains(edge.prerequisiteId)) {
        prerequisites[edge.conceptId]!.add(edge.prerequisiteId);
      }
      if (!dependents[edge.prerequisiteId]!.contains(edge.conceptId)) {
        dependents[edge.prerequisiteId]!.add(edge.conceptId);
      }
    }

    final graph = KnowledgeGraph._(map, prerequisites, dependents);
    final cycle = graph._findCycle();
    if (cycle.isNotEmpty) throw GraphCycleException(cycle);
    return graph;
  }

  /// Semua id konsep dalam graf.
  Set<String> get conceptIds => Set.of(_concepts.keys);

  String _require(String id) {
    if (!_concepts.containsKey(id)) {
      throw ArgumentError('Konsep tak dikenal: $id.');
    }
    return id;
  }

  /// Prasyarat langsung dari [id] (urutan edge, tanpa duplikat).
  List<String> prerequisitesOf(String id) {
    return List.unmodifiable(_prerequisites[_require(id)]!);
  }

  /// Konsep yang langsung bergantung pada [id].
  List<String> dependentsOf(String id) {
    return List.unmodifiable(_dependents[_require(id)]!);
  }

  /// Semua prasyarat [id], langsung maupun tidak langsung.
  Set<String> ancestorsOf(String id) {
    _require(id);
    final result = <String>{};
    final queue = Queue<String>.from(_prerequisites[id]!);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (result.add(current)) {
        queue.addAll(_prerequisites[current]!);
      }
    }
    result.remove(id);
    return result;
  }

  /// True bila graf mengandung siklus (tak pernah terjadi pasca-konstruksi
  /// karena konstruktor melempar [GraphCycleException]).
  bool hasCycle() => _findCycle().isNotEmpty;

  /// Satu siklus sebagai daftar id (kosong bila asiklik).
  List<String> _findCycle() {
    const unvisited = 0;
    const visiting = 1;
    const done = 2;
    final state = {for (final id in _concepts.keys) id: unvisited};
    final stack = <String>[];
    List<String> found = const [];

    bool visit(String id) {
      state[id] = visiting;
      stack.add(id);
      for (final next in _dependents[id]!) {
        if (state[next] == visiting) {
          found = [...stack.sublist(stack.indexOf(next)), next];
          return true;
        }
        if (state[next] == unvisited && visit(next)) return true;
      }
      stack.removeLast();
      state[id] = done;
      return false;
    }

    for (final id in _concepts.keys) {
      if (state[id] == unvisited && visit(id)) break;
    }
    return found;
  }

  /// Urutan topologis semua konsep (prasyarat sebelum lanjutan).
  List<String> topologicalOrder() {
    final cached = _topoCache;
    if (cached != null) return cached;

    final inDegree = <String, int>{
      for (final id in _concepts.keys) id: _prerequisites[id]!.length,
    };
    final queue = Queue<String>.from(
      _concepts.keys.where((id) => inDegree[id] == 0),
    );
    final order = <String>[];
    final added = <String>{};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      order.add(current);
      added.add(current);
      for (final next in _dependents[current]!) {
        inDegree[next] = inDegree[next]! - 1;
        if (inDegree[next] == 0) queue.add(next);
      }
    }
    // Pertahanan: tak terjangkau bila konstruksi tervalidasi.
    for (final id in _concepts.keys) {
      if (!added.contains(id)) order.add(id);
    }

    _topoCache = List.unmodifiable(order);
    return _topoCache!;
  }

  /// Hitung status tiap konsep dari state siswa.
  ///
  /// - mastered tetap mastered;
  /// - terkunci bila ada prasyarat (langsung/tak langsung) belum mastered;
  /// - open bila semua prasyarat mastered dan belum dikerjakan;
  /// - learning bila pernah dikerjakan tetapi belum lulus.
  Map<String, ConceptStatus> computeStatuses(
    Map<String, StudentConceptState> states,
  ) {
    final result = <String, ConceptStatus>{};
    for (final id in _concepts.keys) {
      final state = states[id];
      if (state?.status == ConceptStatus.mastered) {
        result[id] = ConceptStatus.mastered;
        continue;
      }
      final hasWeakPrereq = ancestorsOf(id).any(
        (ancestor) => states[ancestor]?.status != ConceptStatus.mastered,
      );
      if (hasWeakPrereq) {
        result[id] = ConceptStatus.locked;
      } else if (state == null || state.nAnswered == 0) {
        result[id] = ConceptStatus.open;
      } else {
        result[id] = ConceptStatus.learning;
      }
    }
    return result;
  }

  /// Susun rencana remedial untuk konsep yang gagal.
  ///
  /// BFS mundur mengumpulkan himpunan lemah W, lalu tentukan akar
  /// masalah R dan kembalikan jalur topologis R + sisa W + konsep awal.
  /// Bila W kosong, jalurnya hanya konsep awal (mengulang materi).
  RemedialPlan buildRemedialPlan(
    String failedConceptId,
    Map<String, ConceptStatus> statuses,
  ) {
    _require(failedConceptId);
    ConceptStatus statusOf(String id) =>
        statuses[id] ?? ConceptStatus.locked;

    final visited = <String>{failedConceptId};
    final queue = Queue<String>.from(_prerequisites[failedConceptId]!);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (visited.add(current)) {
        queue.addAll(_prerequisites[current]!);
      }
    }

    final weak = visited
        .where((id) =>
            id != failedConceptId &&
            statusOf(id) != ConceptStatus.mastered)
        .toSet();
    if (weak.isEmpty) {
      return RemedialPlan(
        failedConceptId: failedConceptId,
        orderedPath: [failedConceptId],
      );
    }

    final roots = weak
        .where((id) => _prerequisites[id]!
            .every((parent) => statusOf(parent) == ConceptStatus.mastered))
        .toSet();

    final order = topologicalOrder();
    List<String> subset(Set<String> ids) =>
        order.where(ids.contains).toList();
    return RemedialPlan(
      failedConceptId: failedConceptId,
      weakIds: weak,
      rootIds: roots,
      orderedPath: [
        ...subset(roots),
        ...subset(weak.difference(roots)),
        failedConceptId,
      ],
    );
  }

  /// Konsep yang baru terbuka setelah [masteredId] dikuasai.
  ///
  /// Yaitu konsep yang saat ini terkunci, bergantung (transitif) pada
  /// [masteredId], dan seluruh prasyaratnya mastered bila [masteredId]
  /// dihitung sudah mastered.
  Set<String> newlyUnlocked(
    String masteredId,
    Map<String, ConceptStatus> statuses,
  ) {
    _require(masteredId);
    bool isMastered(String id) =>
        id == masteredId || statuses[id] == ConceptStatus.mastered;

    final result = <String>{};
    for (final id in _concepts.keys) {
      if (id == masteredId) continue;
      if ((statuses[id] ?? ConceptStatus.locked) != ConceptStatus.locked) {
        continue;
      }
      if (!ancestorsOf(id).contains(masteredId)) continue;
      if (ancestorsOf(id).every(isMastered)) result.add(id);
    }
    return result;
  }
}
