// Kontrak repository katalog belajar (domain, tanpa import Flutter).
import '../models/concept.dart';
import '../models/concept_edge.dart';
import '../models/learning_material.dart';

/// Katalog konsep, relasi prasyarat, dan materi. Galat berupa [AppException].
abstract class ConceptRepository {
  /// Semua konsep terurut `order_index`.
  Future<List<Concept>> fetchConcepts();

  /// Semua relasi prasyarat.
  Future<List<ConceptEdge>> fetchEdges();

  /// Materi ringkas satu konsep. Melempar bila belum tersedia.
  Future<LearningMaterial> fetchMaterial(String conceptId);
}
