import 'dart:collection';

/// Graf prasyarat antar-konsep (Knowledge Graph).
///
/// Representasi minimal: peta `conceptId -> daftar prerequisiteId`.
/// Algoritma lengkap (sort/path) menyusul di langkah graf.
///
/// Logika murni — tanpa import Flutter.
class ConceptGraph {
  final Map<String, List<String>> _prerequisites;

  ConceptGraph([Map<String, List<String>>? prerequisites])
      : _prerequisites = {
          for (final entry in (prerequisites ?? {}).entries)
            entry.key: List.unmodifiable(entry.value),
        };

  /// Daftar semua id konsep yang dikenal graf.
  Set<String> get conceptIds {
    final ids = <String>{..._prerequisites.keys};
    for (final prereqs in _prerequisites.values) {
      ids.addAll(prereqs);
    }
    return ids;
  }

  /// Prasyarat langsung dari [conceptId].
  List<String> prerequisitesOf(String conceptId) {
    return _prerequisites[conceptId] ?? const [];
  }

  /// Apakah [conceptId] terbuka bila [masteredIds] sudah dikuasai.
  bool isUnlocked(String conceptId, Set<String> masteredIds) {
    for (final prereq in prerequisitesOf(conceptId)) {
      if (!masteredIds.contains(prereq)) return false;
    }
    return true;
  }

  /// Urutan topologi sederhana (Kahn) untuk subset [subsetIds].
  ///
  /// Mengembalikan urutan dari prasyarat ke lanjutan.
  /// Bila ada siklus, sisa node dikembalikan apa adanya di akhir.
  List<String> topologicalSort(List<String> subsetIds) {
    final subset = subsetIds.toSet();
    final inDegree = <String, int>{for (final id in subset) id: 0};
    final children = <String, List<String>>{for (final id in subset) id: []};

    for (final id in subset) {
      for (final parent in prerequisitesOf(id)) {
        if (subset.contains(parent)) {
          children[parent]!.add(id);
          inDegree[id] = (inDegree[id] ?? 0) + 1;
        }
      }
    }

    final queue = Queue<String>();
    for (final id in subset) {
      if (inDegree[id] == 0) queue.add(id);
    }

    final result = <String>[];
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(current);
      for (final child in children[current]!) {
        inDegree[child] = inDegree[child]! - 1;
        if (inDegree[child] == 0) queue.add(child);
      }
    }

    // Siklus: tambahkan sisa yang belum dikunjungi.
    for (final id in subset) {
      if (!result.contains(id)) result.add(id);
    }
    return result;
  }
}
