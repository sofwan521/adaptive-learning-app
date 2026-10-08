import 'dart:collection';
import '../models/concept.dart';

/// Node untuk graph representation
class GraphNode {
  final String id;
  final Concept concept;
  final List<String> children; // Concepts yang depend on this
  final List<String> parents; // Prerequisites

  GraphNode({
    required this.id,
    required this.concept,
    List<String>? children,
    List<String>? parents,
  }) : children = children ?? [],
       parents = parents ?? [];
}

/// Service untuk mengelola Knowledge Graph
class KnowledgeGraphService {
  final Map<String, GraphNode> _graph = {};

  /// Inisialisasi graph dengan daftar konsep
  void initializeGraph(List<Concept> concepts) {
    _graph.clear();

    // Buat nodes
    for (final concept in concepts) {
      _graph[concept.id] = GraphNode(
        id: concept.id,
        concept: concept,
        parents: List.from(concept.prerequisites),
      );
    }

    // Bangun relasi children
    for (final node in _graph.values) {
      for (final parentId in node.parents) {
        if (_graph.containsKey(parentId)) {
          _graph[parentId]!.children.add(node.id);
        }
      }
    }
  }

  /// Dapatkan konsep berdasarkan ID
  Concept? getConcept(String conceptId) {
    return _graph[conceptId]?.concept;
  }

  /// Dapatkan semua konsep
  List<Concept> getAllConcepts() {
    return _graph.values.map((node) => node.concept).toList();
  }

  /// Cek apakah konsep terkunci (prerequisites belum selesai)
  bool isConceptLocked(String conceptId, Set<String> masteredConceptIds) {
    final node = _graph[conceptId];
    if (node == null) return true;

    // Konsep terkunci jika ada prerequisite yang belum dikuasai
    for (final prereqId in node.parents) {
      if (!masteredConceptIds.contains(prereqId)) {
        return true;
      }
    }

    return false;
  }

  /// Dapatkan prerequisites yang belum dikuasai
  List<Concept> getMissingPrerequisites(
    String conceptId,
    Set<String> masteredConceptIds,
  ) {
    final node = _graph[conceptId];
    if (node == null) return [];

    final missing = <Concept>[];

    for (final prereqId in node.parents) {
      if (!masteredConceptIds.contains(prereqId)) {
        final prereqConcept = getConcept(prereqId);
        if (prereqConcept != null) {
          missing.add(prereqConcept);
        }
      }
    }

    return missing;
  }

  /// Dapatkan learning path dari konsep yang gagal
  /// Menggunakan topological sort untuk menentukan urutan belajar
  List<Concept> getRemediallPath(
    String failedConceptId,
    Set<String> masteredConceptIds,
  ) {
    final path = <Concept>[];
    final visited = <String>{};
    final queue = Queue<String>();

    // Mulai dari konsep yang gagal
    queue.add(failedConceptId);

    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();

      if (visited.contains(currentId)) continue;
      visited.add(currentId);

      final node = _graph[currentId];
      if (node == null) continue;

      // Cek prerequisites
      for (final prereqId in node.parents) {
        if (!masteredConceptIds.contains(prereqId) && !visited.contains(prereqId)) {
          queue.add(prereqId);
        }
      }
    }

    // Topological sort untuk menentukan urutan
    final sortedIds = topologicalSort(visited.toList());

    for (final id in sortedIds) {
      final concept = getConcept(id);
      if (concept != null && !masteredConceptIds.contains(id)) {
        path.add(concept);
      }
    }

    return path;
  }

  /// Topological sort untuk mengurutkan konsep berdasarkan dependencies
  List<String> topologicalSort(List<String> conceptIds) {
    final inDegree = <String, int>{};
    final adjList = <String, List<String>>{};

    // Inisialisasi
    for (final id in conceptIds) {
      inDegree[id] = 0;
      adjList[id] = [];
    }

    // Hitung in-degree
    for (final id in conceptIds) {
      final node = _graph[id];
      if (node == null) continue;

      for (final childId in node.children) {
        if (conceptIds.contains(childId)) {
          adjList[id]!.add(childId);
          inDegree[childId] = (inDegree[childId] ?? 0) + 1;
        }
      }
    }

    // Kahn's algorithm
    final queue = Queue<String>();
    final result = <String>[];

    // Tambahkan node dengan in-degree 0
    for (final id in conceptIds) {
      if (inDegree[id] == 0) {
        queue.add(id);
      }
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(current);

      for (final neighbor in adjList[current]!) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    return result;
  }

  /// Dapatkan konsep yang bisa dipelajari selanjutnya
  List<Concept> getAvailableConcepts(Set<String> masteredConceptIds) {
    final available = <Concept>[];

    for (final node in _graph.values) {
      // Skip jika sudah dikuasai
      if (masteredConceptIds.contains(node.id)) continue;

      // Cek apakah prerequisites sudah terpenuhi
      final isLocked = isConceptLocked(node.id, masteredConceptIds);

      if (!isLocked) {
        available.add(node.concept);
      }
    }

    // Urutkan berdasarkan difficulty
    available.sort((a, b) => a.difficulty.compareTo(b.difficulty));

    return available;
  }

  /// Dapatkan semua descendants (konsep yang depend on concept ini)
  List<Concept> getDescendants(String conceptId) {
    final descendants = <Concept>[];
    final visited = <String>{};
    final queue = Queue<String>();

    queue.add(conceptId);

    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();

      if (visited.contains(currentId)) continue;
      visited.add(currentId);

      final node = _graph[currentId];
      if (node == null) continue;

      for (final childId in node.children) {
        if (!visited.contains(childId)) {
          queue.add(childId);
          final childConcept = getConcept(childId);
          if (childConcept != null) {
            descendants.add(childConcept);
          }
        }
      }
    }

    return descendants;
  }

  /// Dapatkan learning path lengkap dari awal sampai target concept
  List<Concept> getFullLearningPath(String targetConceptId) {
    final path = <String>[];
    final visited = <String>{};

    void dfs(String currentId) {
      if (visited.contains(currentId)) return;
      visited.add(currentId);

      final node = _graph[currentId];
      if (node == null) return;

      // Visit prerequisites first
      for (final prereqId in node.parents) {
        dfs(prereqId);
      }

      path.add(currentId);
    }

    dfs(targetConceptId);

    return path.map((id) => getConcept(id)).whereType<Concept>().toList();
  }

  /// Update status konsep
  void updateConceptStatus(String conceptId, {
    bool? isMastered,
    double? masteryPercentage,
  }) {
    final node = _graph[conceptId];
    if (node == null) return;

    _graph[conceptId] = GraphNode(
      id: node.id,
      concept: node.concept.copyWith(
        isMastered: isMastered,
        masteryPercentage: masteryPercentage,
      ),
      children: node.children,
      parents: node.parents,
    );
  }

  /// Hitung total konsep dalam graph
  int getTotalConcepts() => _graph.length;

  /// Hitung berapa konsep yang sudah dikuasai
  int getMasteredCount(Set<String> masteredConceptIds) {
    return masteredConceptIds.length;
  }

  /// Hitung progress percentage
  double getProgressPercentage(Set<String> masteredConceptIds) {
    if (_graph.isEmpty) return 0.0;
    return (masteredConceptIds.length / _graph.length * 100).clamp(0.0, 100.0);
  }
}
